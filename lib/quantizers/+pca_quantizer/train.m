function [model, projections] = train(samples, varargin)
%TRAIN Train a PCA quantizer.

  THRESHOLD = .99;      % Account 99% of data.
  PRECISION = 'double'; % Data type.
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Threshold', THRESHOLD = varargin{i+1};
      case 'Precision', PRECISION = varargin{i+1};
    end
  end
  typefun = str2func(PRECISION);

  % Check if the input is row vectors.
  assert(isnumeric(samples));
  if ndims(samples) > 2
    siz = size(samples);
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  samples = typefun(samples);
  
  model.name = 'pca_quantizer';
  [normalized_samples, mu, sigma] = zscore(samples);
  [coeff, projections, latent] = princomp(normalized_samples, 'econ');
  index = (cumsum(latent) / sum(latent)) <= THRESHOLD;
  assert(any(index));
  
  sigma(sigma==0) = 1;
  model.mu = mu;
  model.sigma = sigma;
  model.coeff = coeff(:, index);
  projections = projections(:, index);

end

