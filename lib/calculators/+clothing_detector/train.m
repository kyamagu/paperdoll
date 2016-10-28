function [config, samples] = train(config, samples, varargin)
%TRAIN Train a clothing detector.

  SAMPLING_RATE = .01;  % Pixel sampling ratio for training.
  SAMPLING_ALPHA = 0.0;
  TRIM_ZERO = true;
  CLASSIFIER_OPTIONS = {...
    'NumFolds', 3,...
    'Solver', 'l2lr',...
    'CRange', 10.^(1:2), ...
    'EpsRange', 10.^-2, ...
    'FeatureOrder', 2,...
    'FeatureIndependent', true,...
    'BetaRange', [0 -.25 -.5],...
    'Quiet', true ...
    };

  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'ClothingDetectorTrimZero'
        TRIM_ZERO = varargin{i+1};
      case 'ClothingDetectorSampleRate'
        SAMPLING_RATE = double(varargin{i+1});
      case 'ClothingDetectorSampleAlpha'
        SAMPLING_ALPHA = double(varargin{i+1});
      case 'ClothingDetectorClassifierOptions'
        CLASSIFIER_OPTIONS = varargin{i+1};
    end
  end
  
  % Check input.
  assert(isstruct(config));
  if ~isempty(config.classifier)
    logger('Computing %s', config.output);
    samples = clothing_detector.apply(config, samples, varargin{:});
    return;
  end
  assert(isstruct(samples));
  assert(isfield(samples, config.annotation));

  % Compute features.
  logger('Obtaining clothing detector features.');
  labels = cell(size(samples));
  features = cell(size(samples));
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), ...
                                       [config.input, config.annotation]);
    annotation = uint8(imread_or_decode(sample.(config.annotation)));
    annotation = annotation(:);
    flattened_features = flatten(config, sample);
    assert(numel(annotation) == size(flattened_features, 1));
    if TRIM_ZERO
      flattened_features = flattened_features(annotation(:) ~= 0, :);
      annotation = annotation(annotation ~= 0);
    end
    % Subsample.
    [labels{i}, features{i}] = subsample_features(annotation, ...
                                                  flattened_features, ...
                                                  SAMPLING_RATE, ...
                                                  'Alpha', SAMPLING_ALPHA, ...
                                                  varargin{:});
  end
  labels = cat(1, labels{:});
  features = cat(1, features{:});
  
  % Report distribution for each category.
  config = report_label_distribution(config, labels);
  
  % Train.
  config.classifier = linear_classifier.train(labels, ...
                                              features, ...
                                              CLASSIFIER_OPTIONS{:});
  % Optionally compute.
  if nargout > 1
    logger('Computing %s', config.output);
    samples = clothing_detector.apply(config, samples, varargin{:});
  end
end

function config = report_label_distribution(config, labels)
%REPORT_LABEL_DISTRIBUTION
  [unique_labels, ~, index] = unique(labels);
  histogram = accumarray(index, 1);
  logger('Ground truth distribution');
  if ~isempty(config.labels)
    config.labels = config.labels(unique_labels);
    for i = 1:numel(unique_labels)
      logger('%15s: %d', config.labels{i}, histogram(i));
    end
  else
    for i = 1:numel(unique_labels)
      logger('%d: %d', unique_labels(i), histogram(i));
    end
  end
end
