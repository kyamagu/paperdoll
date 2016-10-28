function [config, samples] = train( config, samples, varargin )
%TRAIN Train a calculator configuration.

  %TODO: learn frame size from samples.

  if nargout > 1
    logger('Computing %s', config.output_image);
    calculator = str2func([config.name,'.apply']);
    samples = calculator(config, samples, varargin{:});
  end

end

