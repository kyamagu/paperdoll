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
  if ~FORCE && all(cellfun(@(x)isfield(samples,x), config.output))
    return
  end
    
  % Compute gradient feature.
  for j = 1:numel(config.output)
    [samples.(config.output{j})] = deal([]);
  end
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    for j = 1:numel(config.output)
      [~, labeling] = max(sample.(config.input{j}), [], 3);
      labeling = uint8(labeling);
      %if ENCODE
        labeling = imencode(labeling);
      %end
      samples(i).(config.output{j}) = labeling;
    end
  end

end