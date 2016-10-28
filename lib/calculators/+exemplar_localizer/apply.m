function samples = apply(config, samples, varargin)
%APPLY Apply clothing detector to input.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  TRIM_LABELS = false;
  TRAINING_OPTIONS = {...
    'ClothingDetectorSampleAlpha', 0.0, ...
    'ClothingDetectorSampleRate', 0.05, ...
    'ClothingDetectorClassifierOptions', {
      'NumFolds', 1, ...
      'CRange', 10.^(-1), ...
      'BetaRange', -0.33, ...
      'Quiet', true ...
    } ...
  };

  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
      case 'ExemplarLocalizerTrimLabels'
        TRIM_LABELS = varargin{i+1};
      case 'ExemplarLocalizerTrainingOptions'
        TRAINING_OPTIONS = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output_localization) ... 
            && isfield(samples, config.output_labels)
    return
  end
  
  TRIM_LABELS = TRIM_LABELS && isfield(samples, config.input_labels);
  
  % Ensure dependency.
  assert(isfield(samples, config.input_exemplar_ids));
  
  % Compute labeling for each.
  [samples.(config.output_localization)] = deal([]);
  [samples.(config.output_labels)] = deal([]);
  for i = 1:numel(samples)
    [samples(i).(config.output_localization), ...
     samples(i).(config.output_labels)] = ...
        process_sample(config, samples(i), TRAINING_OPTIONS, TRIM_LABELS);
    %show_parsing(samples(i).normal_image, ...
    %             samples(i).(config.output_localization), ...
    %             samples(i).(config.output_labels));
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), ...
                                             config.output_localization);
    end
  end

end

function [localization, labels] = process_sample(config, sample, train_options, trim_labels)
  % Train a local pipeline from the retrieved samples.
  exemplars = load_exemplars(config, sample);
  sample_labels = repmat(sample.(config.input_labels), 1, trim_labels);
  [exemplars, labels] = relabel_exemplars(config, exemplars, sample_labels);
  local_pipeline = config.local_pipeline;
  local_pipeline{end}.labels = labels;
  local_pipeline = feature_calculator.train(local_pipeline, ...
                                            exemplars, ...
                                            train_options{:}, ...
                                            'Verbose', false, ...
                                            'ClothingDetectorTrimZero', true);
  % Predict.
  sample = feature_calculator.apply(local_pipeline, sample, ...
                                    'ClothingDetectorNormalize', false);
  localization = sample.(config.output_localization);
  labels = local_pipeline{end}.labels;

  [localization, labels] = reorder_labels(localization, labels);
  
  % Only keep the specified labels in that order.
  if trim_labels && isfield(sample, config.input_labels)
    localization = extract_specified_labels(localization, ...
                                            labels, ...
                                            sample.(config.input_labels));
    labels = sample.(config.input_labels);
  end
  %show_parsing(sample.rgb, localization, labels);
end

function exemplars = load_exemplars(config, sample)
  persistent database_id;
  if isempty(database_id)
    database_id = bdb.open(config.database_file);
  end
  exemplar_ids = sample.(config.input_exemplar_ids);
  exemplar_ids = exemplar_ids(1:min(config.max_exemplars, ...
                                    numel(exemplar_ids)));
  logger('Retrieving %d nearest neighbors.', numel(exemplar_ids));
  exemplars = cell(size(exemplar_ids));
  for i = 1:numel(exemplars)
    exemplars{i} = bdb.get(database_id, exemplar_ids(i));
  end
  exemplars = [exemplars{:}];
end

function [exemplars, labels] = relabel_exemplars(config, exemplars, sample_labels)
%RELABEL_EXEMPLARS
  labels = setdiff([exemplars.(config.exemplar_labels)], 'unknown');
  if ~isempty(sample_labels)
    labels = intersect(sample_labels, labels);
  end
  for i = 1:numel(exemplars)
    exemplar_labels = exemplars(i).(config.exemplar_labels);
    label_mapping = zeros(size(exemplar_labels));
    for j = 1:numel(exemplar_labels)
      label_id = find(strcmp(exemplar_labels{j}, labels));
      if ~isempty(label_id)
        label_mapping(j) = label_id;
      end
    end
    labeling = imread_or_decode(exemplars(i).(config.exemplar_labeling), 'png');
    labeling = label_mapping(labeling);
    exemplars(i).(config.exemplar_labeling) = labeling;
  end
end

function new_localization = extract_specified_labels(localization, labels, new_labels)
  new_localization = zeros(size(localization, 1), ...
                           size(localization, 2), ...
                           numel(new_labels));
  for i = 1:numel(new_labels)
    label_id = strcmp(new_labels{i}, labels);
    if ~any(label_id)
      warning('exemplar_localizer:apply', ...
              'Label %s not found in the exemplars', new_labels{i});
    else
      new_localization(:,:,i) = localization(:,:,label_id);
    end
  end
end

function [localization, labels] = reorder_labels(localization, labels)
  reserved_labels = {'null', 'skin', 'hair'};
  reserved_indices = cellfun(@(x)find(strcmp(x,labels)), reserved_labels);
  order = [reserved_indices, setdiff(1:numel(labels), reserved_indices)];
  localization = localization(:,:,order);
  labels = labels(order);
end

% function show_parsing(rgb_image, localization, labels)
%   subplot(1, 2, 1);
%   imshow(imread_or_decode(rgb_image, 'jpg'));
%   subplot(1, 2, 2);
%   [~, labeling] = max(localization, [], 3);
%   colors = [1,1,1;1,.75,.75;.2,.1,.1;hsv(numel(labels) - 3)];
%   imshow(labeling, colors);
%   colorbar('YTickLabel', labels, 'YTick', 1:numel(labels));
% end