function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(iscell(config));

  ENCODE = false;
  RESCUE = true;
  for i = 1:2:numel(varargin)
   switch varargin{i}
     case 'Encode', ENCODE = varargin{i+1};
     case 'Rescue', RESCUE = varargin{i+1};
   end
  end

  calculators = cellfun(@(x)str2func([x.name, '.apply']), config, ...
                        'UniformOutput', false);
  output_samples = cell(size(samples));
  for i = 1:numel(samples)
    if numel(samples) > 1
      logger('feature_calculator: %d / %d', i, numel(samples));
    end
    try
      sample = feature_calculator.decode(samples(i));
      for j = 1:numel(config)
        sample = calculators{j}(config{j}, sample, varargin{:}, 'Encode', false);
      end
      output_samples{i} = sample;
      if ENCODE
        output_samples{i} = feature_calculator.encode(output_samples{i});
      end
    catch e
      logger('Error:feature_calculator: %d / %d', i, numel(samples));
      disp(e.getReport);
      if ~RESCUE, rethrow(e); end
    end
  end
  samples = cat(1, output_samples{:});

end
