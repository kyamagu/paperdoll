function [config, samples] = train(config, samples, varargin)
%TRAIN Train a combined localizer.
  
  % Check input.
  assert(isstruct(config));
  assert(isstruct(samples));
  assert(isfield(samples, config.annotation));
  for i = 1:numel(config.input)
    assert(isfield(samples, config.input{i}));
  end

  % Prepare data.
  [annotations, localizations] = prepare_fitting_data(config, samples);
  
  % Solve the optimization.
  objective_function = @(lambdas) 1-compute_accuracy(annotations, ...
                                                     localizations, ...
                                                     lambdas);
  initial_lambdas = ones(size(config.input)) / numel(config.input);
  options = optimset(...
    'Display', 'iter' ...
    );
  [best_lambdas, score] = fminsearch(objective_function, ...
                                     initial_lambdas, ...
                                     options);
  logger('Best lambdas = [%s ] at accuracy = %g', ...
         sprintf(' %g', best_lambdas), ...
         1 - score);
  config.lambdas = best_lambdas;

  % Optionally compute.
  if nargout > 1
    logger('Computing %s', config.output);
    samples = combined_localizer.apply(config, samples, 'Encode', true);
  end
end

function [annotations, localizations] = prepare_fitting_data(config, samples)
%PREPARE_FITTING_DATA

  % NOTE: This requires huge memory!
  annotations = cell(size(samples));
  localizations = cell(numel(samples), numel(config.input));
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    annotation = imread_or_decode(sample.(config.annotation), 'png');
    %annotations{i} = uint8(annotation(:));
    foreground_index = annotation(:) ~= 1;
    annotations{i} = uint8(annotation(foreground_index));
    for j = 1:numel(config.input)
      localization = sample.(config.input{j});
      image_size = size(localization);
      localization = reshape(localization, ...
                             prod(image_size(1:2)), ...
                             image_size(3));
      localization = remap_labels(localization, ...
                                  sample.(config.input_labels{j}), ...
                                  sample.(config.annotation_labels));
      %localizations{i,j} = single(log(localization));
      assert(isreal(localization));
      log_localization = single(log(localization(foreground_index, :)));
      assert(isreal(log_localization));
      localizations{i,j} = log_localization;
    end
  end
  annotations = cat(1, annotations{:});
  localizations = arrayfun(@(i)cat(1, localizations{:,i}), ...
                           1:numel(config.input), ...
                           'UniformOutput', false);
  localizations = cat(3, localizations{:});
  localizations = reshape(localizations, ...
                          size(localizations, 1) * size(localizations, 2), ...
                          size(localizations, 3));
end

function mapped_localization = remap_labels(localization, labels, annotation_labels)
%REMAP_LABELS
  label_mapping = cellfun(@(x)find(strcmp(x,annotation_labels)), ...
                          labels, ...
                          'UniformOutput', false);
  nonempty_index = ~cellfun(@isempty, label_mapping);
  mapped_localization = ones(size(localization, 1), ...
                             numel(annotation_labels), ...
                             'single') * eps;
  mapped_localization(:,[label_mapping{nonempty_index}]) = ...
      localization(:,nonempty_index);
end

function score = compute_accuracy(annotations, localizations, lambdas)
%COMPUTE_ACCURACY
  scores = localizations * single(lambdas(:));
  scores = reshape(scores, ...
                   size(annotations, 1), ...
                   size(localizations, 1) / size(annotations, 1));
  [~, predictions] = max(scores, [], 2);
  score = nnz(annotations == uint8(predictions)) / numel(annotations);
end
