function [model, projections] = train(samples, varargin)
%TRAIN Train a raw quantizer.

  % Check if the input is row vectors.
  assert(isnumeric(samples));
  if ndims(samples) > 2
    siz = size(samples);
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  
  model.name = 'raw_quantizer';
  [projections, model.mu, model.sigma] = zscore(samples);

end

