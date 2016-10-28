function samples = apply(config, samples, varargin)
%APPLY Apply clothing detector to input.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  PRECOMPUTE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
      case 'Precompute', PRECOMPUTE = varargin{i+1};
    end
  end

  % Only run precomputation.
  if PRECOMPUTE
    samples = exemplar_localizer2.precompute(config, samples, varargin{:});
    return;
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output_localization) ... 
            && isfield(samples, config.output_labels)
    return
  end
  
  % Ensure dependency.
  assert(isfield(samples, config.input_exemplar_ids));
  
  % Compute labeling for each.
  [samples.(config.output_localization)] = deal([]);
  [samples.(config.output_labels)] = deal([]);
  for i = 1:numel(samples)
    [samples(i).(config.output_localization), ...
     samples(i).(config.output_labels)] = process_sample(config, samples(i));
    %show_parsing(samples(i).normal_image, ...
    %             samples(i).(config.output_localization), ...
    %             samples(i).(config.output_labels));
    if ENCODE
      samples(i).(config.output_localization) = encode_3d_array(...
          samples(i).(config.output_localization));
    end
  end

end

function [localization, labels] = process_sample(config, sample)
%PROCESS_SAMPLE
  % Train a classifier from the retrieved samples.
  exemplars = load_exemplars(config, sample);
  sample_labels = sample.(config.input_labels);
  [exemplars, labels] = relabel_exemplars(config, exemplars, sample_labels);
  [training_annotation, training_features, labels] = ...
      get_training_samples(config, exemplars, labels);
  classifier = linear_classifier.train(training_annotation, ...
                                       training_features, ...
                                       config.training_options{:});
  % Predict.
  sample = feature_calculator.decode(sample, config.input);
  features = flatten(config, sample);
  [~, probabilities] = linear_classifier.predict(classifier, features);
  image_size = size(sample.(config.input{1}));
  localization = reshape(probabilities, ...
                         [image_size(1:2), size(probabilities, 2)]);
  [localization, labels] = reorder_labels(localization, labels);
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
    exemplar_labels = [exemplars(i).(config.exemplar_labels), 'unknown'];
    label_mapping = zeros(size(exemplar_labels));
    for j = 1:numel(exemplar_labels)
      label_id = find(strcmp(exemplar_labels{j}, labels));
      if ~isempty(label_id)
        label_mapping(j) = label_id;
      end
    end
    annotation = label_mapping(exemplars(i).(config.exemplar_annotation));
    exemplars(i).(config.exemplar_annotation) = annotation(:);
  end
end

function [annotation, features, labels] = get_training_samples(config, exemplars, labels)
%GET_TRAINING_SAMPLES
  annotation = cat(1, exemplars.(config.exemplar_annotation));
  features = cat(1, exemplars.(config.exemplar_features));
  features = double(features(annotation ~= 0, :));
  annotation = annotation(annotation ~= 0, :);
  labels = labels(unique(annotation));
end

function [localization, labels] = reorder_labels(localization, labels)
  reserved_labels = {'null', 'skin', 'hair'};
  reserved_indices = cellfun(@(x)find(strcmp(x,labels)), reserved_labels);
  order = [reserved_indices, setdiff(1:numel(labels), reserved_indices)];
  localization = localization(:,:,order);
  labels = labels(order);
end