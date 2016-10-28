function [config, samples] = train(config, samples, varargin)
%TRAIN Train a clothing localizer.
%
% ## Input
%   config: struct of the localizer configuration.
%  samples: struct array of training samples.
%
% ## Output
%    config: struct of the trained model.
%   samples: struct array of training samples with computed features.
%

  SAMPLING_RATE = .03;  % Pixel sampling ratio for training.
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'ClothingLocalizerSampleRate'
        SAMPLING_RATE = double(varargin{i+1});
    end
  end
  
  % Check input.
  assert(isstruct(config));
  if ~isempty(config.classifiers)
    logger('Computing %s', config.output);
    samples = clothing_localizer.apply(config, samples, varargin{:});
    return;
  end
  assert(isstruct(samples));
  assert(isfield(samples, config.annotation));

  % Compute features.
  logger('Computing clothing detector features.');
  labels = cell(size(samples));
  features = cell(size(samples));
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), ...
                                       [config.input, config.annotation]);
    annotation = imread_or_decode(sample.(config.annotation));
    flattened_features = flatten(config, sample);
    assert(numel(annotation) == size(flattened_features, 1));
    % Subsample.
    [labels{i}, features{i}] = subsample_features(annotation(:), ...
                                                  flattened_features, ...
                                                  SAMPLING_RATE, ...
                                                  'Alpha', 0.1);
  end
  
  % Get information about which image contains which label.
  unique_labels = unique(cat(1, labels{:}));
  taggings = false(numel(labels), numel(unique_labels));
  for i = 1:numel(labels)
    taggings(i,:) = arrayfun(@(label)any(label==labels{i}), unique_labels);
  end
  config = report_label_distribution(config, cat(1, labels{:}));
  
  % Train.
  classifiers = cell(size(unique_labels));
  for i = 1:numel(unique_labels)
    training_labels = cat(1, labels{taggings(:, i)}) == unique_labels(i);
    training_features = cat(1, features{taggings(:, i)});
    classifiers{i} = linear_classifier.train(training_labels, ...
                                             training_features, ...
                                             'Solver', 'l2lr',...
                                             'CRange', 10.^(1:2), ...
                                             'EpsRange', 10.^-2, ...
                                             'FeatureOrder', 2,...
                                             'FeatureIndependent', true,...
                                             'BetaRange', [0, -.25, -.5],...
                                             'Quiet', true);
  end
  config.classifiers = [classifiers{:}];
  % Optionally compute.
  if nargout > 1
    logger('Computing %s', config.output);
    samples = clothing_localizer.apply(config, samples, varargin{:});
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
      logger('%14s: %d', config.labels{i}, histogram(i));
    end
  else
    config.labels = arrayfun(@num2str, unique_labels, 'UniformOutput', false);
    for i = 1:numel(unique_labels)
      logger('%g: %d', unique_labels(i), histogram(i));
    end
  end
end
