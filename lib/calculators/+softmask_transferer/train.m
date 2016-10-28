function [config, samples] = train(config, samples, varargin)
%TRAIN Train a softmask transferer config.
%
% ## Input
%  samples: struct array of the training samples.
%
% ## Output
%   config: struct of the trained config.
%

  assert(isstruct(config));
  if isfield(config, 'quantizers')
    logger('Computing %s', config.output);
    samples = softmask_transferer.apply(config, samples, varargin{:});
    return;
  end
  
  % Sample dense features.
  logger('softmask: sampling dense features.');
  features = cell(numel(samples), numel(config.input));
  for i = 1:numel(samples)
    if mod(i, 100) == 1, logger('%04d / %04d', i, numel(samples)); end
    sample = feature_calculator.decode(samples(i), config.input);
    subsampled_pixel_index = subsample_pixels(size(sample.(config.input{1})));
    for j = 1:numel(config.input)
      dense_feature = sample.(config.input{j});
      row_features = reshape(dense_feature, ...
                             [size(dense_feature, 1)*size(dense_feature,2), ...
                              size(dense_feature, 3)]);
      features{i, j} = row_features(subsampled_pixel_index, :);
    end
  end
  
  % Train quantizers.
  for j = 1:numel(config.input)
    row_features = cat(1, features{:, j});
    logger('Training %d-d visual word dictionary for %d of %d-d features.', ...
           config.num_visual_words, ...
           size(row_features, 1), ...
           size(row_features, 2));
    config.quantizers(j) = kmeans_quantizer2.train(row_features, ...
                                                   'NumClusters', config.num_visual_words, ...
                                                   'Normalize', false);
  end
  
  % Optionally compute features for samples.
  if nargout > 1
    logger('Computing %s', config.output);
    samples = softmask_transferer.apply(config, samples, varargin{:});
  end

end

function subsampled_pixel_index = subsample_pixels(image_size)
%SUBSAMPLE_PIXELS
  subsampled_pixel_index = 1:32:prod(image_size(1:2)); % TODO(Hadi): be smart!
end
