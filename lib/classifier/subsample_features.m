function [labels, features] = subsample_features(labels, features, sampling_rate, varargin)
%SUBSAMPLE_FEATURES Subsample labels and features at the specified rate.
%
%    [labels, features] = subsample_features(labels, features, sampling_rate)
%
% The function subsamples input pairs of (label, feature). LABELS must be a
% vector of numeric or logical values. FEATURES must be row vectors of any
% type. The number of elements in LABELS must match the number of rows of
% FEATURES. The SAMPLING_RATE is the approximate rate of the acceptance in
% overall.
%
% ## Options
%
% * `Alpha`  Parameter to control the sampling rate for each class according to
%            the frequency. The resulting frequency of the output is
%            proportional to P^(ALPHA). When ALPHA = 0, the resulting 
%            LABELS follows uniform distribution. Default 0.5.
%

  ALPHA = 0.5;
  VERBOSE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Alpha', ALPHA = varargin{i+1};
      case 'Verbose', VERBOSE = varargin{i+1};
    end
  end

  [unique_labels, ~, index] = unique(full(labels));
  histogram = accumarray(index, 1);
  probability = histogram ./ sum(histogram);
  target_probability = probability.^(ALPHA);
  thresholds = (target_probability ./ probability) *...
               sampling_rate / sum(target_probability);
  accepted_index = cell(size(unique_labels));
  for i = 1:numel(unique_labels)
    label_index = find(labels == unique_labels(i));
    accepted_index{i} = label_index(rand(size(label_index))<thresholds(i));
    if VERBOSE
      logger('label %d: %d / %d', unique_labels(i), ...
                                  numel(accepted_index{i}), ...
                                  numel(label_index));
    end
  end
  accepted_index = cat(1, accepted_index{:});
  if VERBOSE
    logger('subsampling: %d / %d = %g for target %g', ...
           numel(accepted_index), ...
           numel(labels), ...
           numel(accepted_index) / numel(labels), ...
           sampling_rate);
  end
  labels = labels(accepted_index);
  features = features(accepted_index, :);
end