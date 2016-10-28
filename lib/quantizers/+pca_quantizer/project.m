function projections = project(model, samples)
%APPLY Apply PCA projection.

  siz = size(samples);
  if numel(siz) > 2
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  
  samples = feval(class(model.mu), samples);
  samples = bsxfun(@minus, samples, model.mu);
  samples = bsxfun(@rdivide, samples, model.sigma);
  projections = samples * model.coeff;
  
  if numel(siz) > 2
    projections = reshape(projections, [siz(1:2), size(projections, 2)]);
  end

end

