function [config, samples] = train(config, samples, varargin)
%TRAIN Train a calculator configuration.
  if nargout > 1
    logger('Applying %s', config.name);
    calculator = str2func([config.name,'.apply']);
    samples = calculator(config, samples, varargin{:});
  end
end