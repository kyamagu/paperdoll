function projections = project(model, samples)
%APPLY Apply normalization.

  siz = size(samples);
  if numel(siz) > 2
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  
  projections = bsxfun(@rdivide, bsxfun(@minus, samples, model.mu), model.sigma);
  
  if numel(siz) > 2
    projections = reshape(projections, [siz(1:2), size(projections, 2)]);
  end

end

