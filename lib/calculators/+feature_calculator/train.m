function [config, samples] = train( config, samples, varargin )
%TRAIN Train a feature calculator pipeline.

  assert(iscell(config));
  varargin = [varargin, 'Encode', true];
  for i = 1:numel(config)
    trainer = str2func([config{i}.name, '.train']);
    if i == numel(config) && nargout < 2
      config{i} = trainer(config{i}, samples, varargin{:});
    else
      [config{i}, samples] = trainer(config{i}, samples, varargin{:});
    end
  end

end

