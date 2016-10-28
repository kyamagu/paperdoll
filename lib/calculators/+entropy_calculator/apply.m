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
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Check dependency.
  assert(all(cellfun(@(x)isfield(samples, x), config.input)));
  
  % Compute mr8 feature.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    samples(i).(config.output) = compute_entropy(config, sample);
  end

end

function output = compute_entropy(config, sample)
  output = cell(numel(config.input));
  for i = 1:numel(config.input)
    im = sample.(config.input{i});
    im = im2double(im);
    entropies = zeros(1, size(im, 3));
    for j = 1:size(im, 3)
      values = im(:,:,j);
      min_value = min(values(:));
      max_value = max(values(:));
      s = max_value - min_value;
      if s == 0, s = 1; end
      entropies(j) = entropy((values - min_value) / s);
    end
    output{i} = entropies;
  end
  output = [output{:}];
end
