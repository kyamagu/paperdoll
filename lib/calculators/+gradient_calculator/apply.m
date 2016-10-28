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
    sample = feature_calculator.decode(samples(i), config.input);
    gray_image = imread_or_decode(sample.(config.input), 'jpg');
    if size(gray_image, 3) == 3, gray_image = rgb2gray(gray_image); end
    [gx, gy] = vl_grad(im2double(gray_image));
    samples(i).(config.output) = cat(3, gx, gy);
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end