function samples = apply(config, samples, varargin)
%APPLY Apply clothing detector to input.
%
%    samples = clothing_detector.apply(config, samples)
%

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  NORMALIZE = true;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
      case 'ClothingDetectorNormalize', NORMALIZE = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && ...
     isfield(samples, config.output) && ...
     ~isempty(samples.(config.output))
    return
  end
  
  % Ensure dependency.
  assert(~isempty(config.classifier));

  % Compute map.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    features = flatten(config, sample);
    [~, probabilities] = linear_classifier.predict(config.classifier, ...
                                                   features, ...
                                                   varargin{:});
    if NORMALIZE
      probabilities = bsxfun(@rdivide, probabilities, sum(probabilities, 2));
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