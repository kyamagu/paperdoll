function classifier = train(labels, samples, varargin)
%TRAIN Train a Gaussian distribution.

  SHRINKAGE = 0.01;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Shrinkage', SHRINKAGE = varargin{i+1};
    end
  end

  %logger('samples = %d, features = %d', size(samples, 1), size(samples, 2));
  
  % Make a sample weight matrix.
  if isempty(labels), labels = ones(size(samples, 1), 1); end
  if isvector(labels) && all(mod(labels, 1) == 0) % Categorical.
    [classifier.labels, ~, labels] = unique(labels);
    weights = accumarray([(1:numel(labels))', labels(:)], ...
                         1, ...
                         [numel(labels), numel(classifier.labels)]);
  else
    classifier.labels = 1:size(labels, 2);
    weights = labels;
    assert(size(weights, 1) == size(samples, 1));
  end
  normal_weights = weights * diag(1 ./ sum(weights, 1));
  
  % Compute weighted mean.
  classifier.mu = normal_weights' * samples;
  classifier.sigma = zeros(size(samples, 2), size(samples, 2), ...
                           numel(classifier.labels));
  classifier.lambda = zeros(size(samples, 2), size(samples, 2), ...
                            numel(classifier.labels));
  classifier.log_coeff = zeros(1, numel(classifier.labels));
  for i = 1:numel(classifier.labels)
    normal_samples = bsxfun(@minus, samples, classifier.mu(i, :));
    sample_sigma = normal_samples' * ...
                   diag(sparse(normal_weights(:, i))) * ...
                   normal_samples;
    % sample_sigma = diag(diag(sample_sigma));
    regularizer = trace(sample_sigma) / size(samples,2);
    classifier.sigma(:,:,i) = (1 - SHRINKAGE) * sample_sigma + ...
                              (SHRINKAGE) * regularizer * eye(size(samples,2));
    classifier.lambda(:,:,i) = inv(classifier.sigma(:,:,i));
    classifier.log_coeff(i) = -0.5 * (size(samples,2) * log(2*pi) + ...
                              log(det(classifier.sigma(:,:,i))));
    if classifier.log_coeff(i) > 0
      warning('gaussian:train', ...
              'Gaussian with log-coeff: %g', classifier.log_coeff(i));
    end
  end
end