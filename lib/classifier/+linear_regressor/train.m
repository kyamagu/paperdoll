function regressor = train(labels, samples, varargin)
%TRAIN Train a linear regressor using liblinear.

  options.normalize = true;
  options.solvers = struct('l2', 11, 'l2_dual', 12, 'l1_dual', 13);
  options.n_folds = 3;
  options.c_range = 10.^(-4:0);
  options.eps_range = 10.^(-2);
  options.feature_order = 2;
  options.feature_independent = true;
  options.solver = 'l2';
  options.quiet = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'NormalizeFeatures', options.normalize = varargin{i+1};
      case 'NumFolds', options.n_folds = varargin{i+1};
      case 'CRange', options.c_range = varargin{i+1};
      case 'EpsRange', options.eps_range = varargin{i+1};
      case 'FeatureOrder', options.feature_order = varargin{i+1};
      case 'FeatureIndependent', options.feature_independent = varargin{i+1};
      case 'Solver', options.solver = varargin{i+1};
      case 'Quiet', options.quiet = varargin{i+1};
    end
  end

  % Normalize the feature representation.
  if options.normalize
    [samples, regressor.normalizer] = train_normalizer(samples);
  end
  regressor.feature_order = options.feature_order;
  regressor.feature_independent = options.feature_independent;
  samples = expand_feature(samples, ...
                           regressor.feature_order, ...
                           'Independent', regressor.feature_independent);
  logger(['Training a regressor: n_folds = %d, order = %d, '...
          'independent = %d, samples = %d, features = %d'], ...
         options.n_folds, ...
         options.feature_order, ...
         options.feature_independent, ...
         size(samples, 1), ...
         size(samples, 2));
  
  labels = full(double(labels));
  samples = sparse(double(samples));
  for i = 1:size(labels, 2)
    regressor.model(i) = train_regressor(labels(:,i), ...
                                         samples, ...
                                         options);
  end
  
end

function [samples, normalizer] = train_normalizer(samples)
%TRAIN_NORMALIZER

  if issparse(samples)
    normalizer.mu = sparse([], [], [], 1, size(samples, 2));
    normalizer.sigma = full(max(samples, [], 1));
    normalizer.sigma(normalizer.sigma <= 1e-6) = 1;
  else
    normalizer.mu = mean(samples, 1);
    normalizer.sigma = 3 * std(samples, [], 1);
    normalizer.sigma(normalizer.sigma <= 1e-6) = 1;
  end
  samples = bsxfun(@minus, samples, normalizer.mu);
  samples = bsxfun(@rdivide, samples, normalizer.sigma);
 
%   max_values = max(samples, [], 1);
%   min_values = min(samples, [], 1);
%   normalizer.mu = min_values;
%   normalizer.sigma = max_values - min_values;
%   normalizer.sigma(normalizer.sigma < 1e-6) = 1;
%   samples = bsxfun(@minus, samples, normalizer.mu);
%   samples = bsxfun(@rdivide, samples, normalizer.sigma);

end

function model = train_regressor(labels, normalized_samples, options)
  if options.n_folds > 1
    % Cross validation to find the best training params.
    squared_errors = zeros(numel(options.c_range), numel(options.eps_range));
    for i = 1:numel(options.c_range)
      for j = 1:numel(options.eps_range)
        logger('C = %f, eps = %f', options.c_range(i), options.eps_range(j));
        liblinear_options = sprintf('-s %d -v %d -c %s -p %s%s',...
                                    options.solvers.(options.solver), ...
                                    options.n_folds, ...
                                    num2str(options.c_range(i)), ...
                                    num2str(options.eps_range(j)),...
                                    repmat(' -q', 1, options.quiet));
        squared_errors(i, j) = liblinear.train(labels,...
                                               normalized_samples,...
                                               liblinear_options);
      end
    end
    index = find(squared_errors(:) == min(squared_errors(:)), 1);
    [row, col] = ind2sub(size(squared_errors), index);
    best_c = options.c_range(row);
    best_eps = options.eps_range(col);
    logger('Best C = %f, eps = %f', best_c, best_eps);
  else
    best_c = options.c_range(1);
    best_eps = options.eps_range(1);
  end
  
  % Train a model.
  liblinear_options = sprintf('-s %d -c %s -p %s%s', ...
                              options.solvers.(options.solver), ...
                              num2str(best_c), ...
                              num2str(best_eps),...
                              repmat(' -q', 1, options.quiet));
  model = liblinear.train(labels,...
                          normalized_samples,...
                          liblinear_options);
  model.w = model.w(:);
end
