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
  
  % Resolve dependency.
  assert(isfield(samples, config.input));
  
  % Compute gradient feature.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    rgb = imread_or_decode(samples(i).(config.input), 'jpg');
    if size(rgb, 3) == 1, rgb = repmat(rgb, [1,1,3]); end
    samples(i).(config.output) = rgb;
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end