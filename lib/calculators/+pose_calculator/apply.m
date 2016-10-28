function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
    end
  end
  
  % Quit if already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Compute normalized image and pose.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    input_image = imread_or_decode(samples(i).(config.input), 'jpg');
    samples(i).(config.output) = pose.estimate(config.model, ...
                                               input_image, ...
                                               'Scale', config.scale);
  end
end