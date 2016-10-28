function [config, samples] = train(config, samples, varargin)
%TRAIN Train a calculator.

  % TODO: Fit training parameters?

  if nargout > 1
    logger('Computing %s', config.output_localization);
    calculator = str2func([config.name,'.apply']);
    samples = calculator(config, samples, varargin{:});
  end
  
end