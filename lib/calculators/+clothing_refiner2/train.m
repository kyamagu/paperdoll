function [config, samples] = train(config, samples, varargin)
%TRAIN Train a clothing refiner.

  if nargout > 1
    logger('Computing %s', config.output);
    calculator = str2func([config.name,'.apply']);
    samples = calculator(config, samples, varargin{:});
  end
  
end