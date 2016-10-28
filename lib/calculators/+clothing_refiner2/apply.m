function samples = apply(config, samples, varargin)
%APPLY Apply clothing refiner to input.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  options.FORCE = false;
  options.BETA = -0.75;
  options.LAMBDA = 0.5;
  options.SMOOTH_COST = [];
  options.GAMMA = 1.0;
  options.ENCODE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', options.FORCE = varargin{i+1};
      case 'Encode', options.ENCODE = varargin{i+1};
      case 'ClothingRefinerBeta', options.BETA = varargin{i+1};
      case 'ClothingRefinerLambda', options.LAMBDA = varargin{i+1};
      case 'ClothingRefinerGamma', options.GAMMA = varargin{i+1};
      case 'ClothingRefinerSmoothCost',options.SMOOTH_COST = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~options.FORCE && isfield(samples, config.output)
    return
  end
  
  % Compute map.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), ...
                                       [config.input_image, ...
                                        config.input_localization, ...
                                        config.input_features]);
    if config.add_unknown_label
      sample = add_unknown_label(config, sample);
    end
    labeling = process_sample(config, sample, options);
    %if options.ENCODE
      labeling = imencode(labeling);
    %end
    samples(i).(config.output) = labeling;
    samples(i).(config.output_labels) = sample.(config.input_labels);
  end

end

function sample = add_unknown_label(config, sample)
%ADD_UNKNOWN_LABEL
  localization = sample.(config.input_localization);
  if size(localization,3)==1 && max(localization(:))>1
    return;
  end
  sample.(config.input_labels) = [sample.(config.input_labels), 'unknown'];
  unknown_probability = ones(size(localization, 1), ...
                             size(localization, 2), 1) / ...
                        (size(localization, 3) + 1);
  sample.(config.input_localization) = cat(3,...
                                           localization, ...
                                           unknown_probability);
end

function labeling = process_sample(config, sample, options)
  rgb_image = sample.(config.input_image);
  features = flatten(config, sample);
  localization = sample.(config.input_localization);
  if size(localization,3)==1 && max(localization(:))>1
    localization = convert_from_categorical_array(localization);
  end
  localization_size = size(localization);
  [~, initial_labeling] = max(localization, [], 3);
  labeling = initial_labeling;
  tolerance_value = numel(labeling);
  for j = 1:10
    % Refine probability for the hard masks.
    unique_labels = unique(labeling);
    if numel(unique_labels) == 1, break; end
    probabilities = reshape(localization, ...
                            prod(localization_size(1:2)), ...
                            localization_size(3));
    model = linear_classifier.train(labeling(:), ...
                                    features,...
                                    'NumFolds', 1, ...
                                    'CRange', 10.^(-3), ...
                                    'BetaRange', options.BETA, ...
                                    'Quiet', true);
    [~, probabilities(:, unique_labels)] = ...
        linear_classifier.predict(model, features);
    % Mix the results.
    probabilities = reshape(probabilities, localization_size);
    mixed_localization = exp(options.LAMBDA * log(localization) + ...
                            (1 - options.LAMBDA) * log(probabilities));
    % Smooth.
    old_labeling = labeling;
    [labeling, neg_ll] = gco_smoother.apply(mixed_localization, ...
                                            rgb_image, ...
                                            'Gamma', options.GAMMA, ...
                                            'SmoothCost', options.SMOOTH_COST);
    old_tolerance_value = tolerance_value;
    tolerance_value = nnz(old_labeling(:) ~= labeling(:));
    relative_improvement = abs(tolerance_value - old_tolerance_value) / ...
                               old_tolerance_value;
    logger('tol = %g, rel = %g, negative_log_likelihood = %g', ...
           tolerance_value, relative_improvement, neg_ll);
    %show_parsing(sample, sample.(config.output_labels), {initial_labeling, labeling});
    %pause;
    if tolerance_value < 100 || relative_improvement < 0.05
      break;
    end
  end
  labeling = uint8(labeling);
end

function likelihoods = convert_from_categorical_array(likelihoods)
  output = zeros(numel(likelihoods), max(likelihoods(:)));
  output(sub2ind(size(output), 1:numel(likelihoods), likelihoods(:)')) = 1;
  likelihoods = reshape(output, [size(likelihoods), size(output,2)]);
end

function features = flatten(config, sample)
%FLATTEN_FEATURES Flatten sample struct into row vectors of dense features.
  features = cellfun(@(name)im2double(sample.(name)), ...
                     config.input_features, ...
                     'UniformOutput', false);
  features = cat(3, features{:});
  features = reshape(features,...
                     [size(features,1)*size(features,2), size(features,3)]);
end

% function show_parsing(sample, labels, label_maps)
% %SHOW_PARSING Plot parsing.
%   original_image = imdecode(sample.normal_image, 'jpg');
%   [pose_struct, pa] = pose.PARSE_to_UCI(sample.normal_pose);
%   pose_struct = pose.point2box(pose_struct, pa);
%   labels = strrep(labels, 'null', 'background');
%   colors = [1,1,1;1,.75,.75;.2,.1,.1;hsv(numel(labels)-4);.5,.5,.5];
%   subplot(1,numel(label_maps)+1,1);
%   pose.show(original_image, pose_struct, pa); %imshow(original_image);
%   for i = 1:numel(label_maps)
%     subplot(1,numel(label_maps)+1,i+1);
%     imshow(label_maps{i}, colors);
%     colorbar('YTickLabel', labels, 'YTick', 1:numel(labels));
%   end
% end
