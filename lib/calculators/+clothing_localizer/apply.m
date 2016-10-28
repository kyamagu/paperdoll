function samples = apply(config, samples, varargin)
%APPLY Apply clothing localizer to input.
%
%    samples = clothing_localizer.apply(config, samples)
%

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  LABELS = [];
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
      case 'ClothingLocalizerLabels', LABELS = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Ensure dependency.
  assert(~isempty(config.classifiers));

  % Compute map.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    features = flatten(config, sample);
    classifier_index = get_classifier_index(config, sample, LABELS);
    probabilities = zeros(size(features, 1), numel(classifier_index));
    for j = 1:numel(classifier_index)
      [~, probabilities(:,j)] = linear_classifier.predict(...
          config.classifiers(classifier_index(j)), features);
    end
    image_size = size(sample.(config.input{1}));
    probabilities = reshape(probabilities, ...
                            [image_size(1:2), size(probabilities, 2)]);
    samples(i).(config.output) = probabilities;
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end

function classifier_index = get_classifier_index(config, sample, LABELS)
  % Get which labels to localize.
  if iscell(LABELS)
    classifier_index = cellfun(@(label)find(strcmp(label, config.labels)), ...
                               LABELS);
  elseif isfield(sample, config.input_labels)
    classifier_index = cellfun(@(label)find(strcmp(label, config.labels)), ...
                               sample.(config.input_labels));
  else
    classifier_index = 1:numel(config.classifiers);
  end
end