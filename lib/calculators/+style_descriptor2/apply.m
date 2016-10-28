function samples = apply(config, samples, varargin)
%APPLY Calculate descriptor from the given samples.
%
  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Compute raw descriptors.
  sample = feature_calculator.decode(samples(1), config.input);
  fake_descriptor = compute_spatial_descriptor(config, sample);
  raw_descriptors = zeros(numel(samples), numel(fake_descriptor));
  raw_descriptors(1,:) = fake_descriptor;
  for i = 2:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    raw_descriptors(i,:) = compute_spatial_descriptor(config, sample);
  end
  
  % Project features.
  reducefun = str2func([config.reducer.name, '.project']);
  reduced_descriptors = reducefun(config.reducer, raw_descriptors);
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    samples(i).(config.output) = reduced_descriptors(i,:);
  end
  
end
