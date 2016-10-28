function [config, samples] = train(config, samples, varargin)
%TRAIN Train an item descriptor config.
%
% ## Input
%  samples: struct array of the training samples.
%
% ## Output
%   config: struct of the trained config.
%  samples: struct array of the training samples.
%

  SAMPLE_RATE = .02;  % Subsampling rate for dense features.
  QUANTIZER = 'raw';  % Type of quantizer for spatial cell.
  REDUCER = 'pca';    % Type of reducer.
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'StyleDescriptor2SampleRate'
        SAMPLE_RATE = varargin{i+1};
      case 'StyleDescriptor2Quantizer'
        QUANTIZER = varargin{i+1};
      case 'StyleDescriptor2Reducer'
        REDUCER = varargin{i+1};
    end
  end

  % Train a feature pipeline.
  assert(isstruct(config));
  if ~isempty(config.reducer)
    logger('Computing %s', config.output);
    samples = style_descriptor2.apply(config, samples);
    return;
  end
  assert(isstruct(samples));
  
  % Compute dense features.
  logger('Sampling dense features for style descriptor.');
  features = cell(size(samples));
  for i = 1:numel(samples)
    if mod(i, 100) == 0, logger('%d / %d', i, numel(samples)); end
    sample = feature_calculator.decode(samples(i), config.input);
    dense_features = get_dense_features(config, sample);
    image_size = size(dense_features);
    dense_features = reshape(dense_features, ...
                             prod(image_size(1:2)), ...
                             image_size(3));
    keypoints = get_keypoints(sample.(config.input_pose));
    mask = make_roi_mask(keypoints, image_size, config.patch_size);
    roi_features = dense_features(mask(:), :);
    features{i} = subsample_dense_features(roi_features, SAMPLE_RATE);
  end
  features = cat(1, features{:});
  
  % Train a cell quantizer.
  trainer = str2func([QUANTIZER, '_quantizer.train']);
  logger('Training %s quantizer.', QUANTIZER);
  config.quantizer = trainer(features);
  
  % Compute raw descriptors.
  logger('Computing spatial descriptors');
  sample = feature_calculator.decode(samples(1), config.input);
  fake_descriptor = compute_spatial_descriptor(config, sample);
  raw_descriptors = zeros(numel(samples), numel(fake_descriptor));
  raw_descriptors(1,:) = fake_descriptor;
  for i = 2:numel(samples)
    if mod(i, 100) == 0, logger('%d / %d', i, numel(samples)); end
    sample = feature_calculator.decode(samples(i), config.input);
    raw_descriptors(i,:) = compute_spatial_descriptor(config, sample);
  end

  % Train a reducer.
  trainer = str2func([REDUCER, '_quantizer.train']);
  logger('Training %s reducer for items.', REDUCER);
  [config.reducer, reduced_descriptors] = trainer(raw_descriptors, ...
                                                  'Precision', 'single');
  
  % Optionally prepare output samples.
  if nargout > 1
    logger('Computing %s', config.output);
    [samples.(config.output)] = deal([]);
    for i = 1:numel(samples)
      samples(i).(config.output) = reduced_descriptors(i,:);
    end
  end

end

function features = subsample_dense_features(features, sample_rate)
%SUBSAMPLE_FEATURES
  index = rand(size(features, 1), 1) <= sample_rate;
  features = features(index, :);
end
