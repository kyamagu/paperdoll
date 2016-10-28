function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Check dependency.
  assert(isfield(samples, config.input));
  
  % Compute mr8 feature.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    im = imread_or_decode(sample.(config.input), 'jpg');
    samples(i).(config.output) = mr8.apply(im);
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end