function [config, samples] = train( config, samples, varargin )
%TRAIN Train a calculator configuration.

  if nargout > 1
    logger('Computing %s', config.output_evaluation);
    calculator = str2func([config.name,'.apply']);
    samples = calculator(config, samples, varargin{:});
  end

end

