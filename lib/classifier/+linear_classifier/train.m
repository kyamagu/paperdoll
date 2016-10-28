function classifier = train(labels, samples, varargin)
%TRAIN Train a linear classifier using liblinear.

  options.normalize = true;
  options.solvers = struct('l2lr',         0, ...
                           'l2l2svc_dual', 1, ...
                           'l2l2svc',      2, ...
                           'l2l1svc_dual', 3, ...
                           'mcsvc',        4, ...
                           'l1l2svc',      5, ...
                           'l1lr',         6, ...
                           'l2lr_dual',    7);
  options.n_folds = 3;
  options.c_range = 10.^(-4:0);
  options.eps_range = 10.^(-3:-1);
  options.feature_order = 2;
  options.feature_independent = true;
  options.solver = 'l2lr';
  options.quiet = false;
  options.beta_range = 0; % [-.5, -.25 0]
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
      case 'BetaRange', options.beta_range = varargin{i+1};
    end
  end

  % Normalize the feature representation.
  if options.normalize
    [samples, classifier.normalizer] = train_normalizer(samples);
  end
  classifier.feature_order = options.feature_order;
  classifier.feature_independent = options.feature_independent;
  samples = expand_feature(samples, classifier.feature_order, ...
                           'Independent', classifier.feature_independent);
  logger(['Training a classifier: n_folds = %d, order = %d, '...
          'independent = %d, samples = %d, features = %d'], ...
         options.n_folds, ...
         options.feature_order, ...
         options.feature_independent, ...
         size(samples, 1), ...
         size(samples, 2));
  label_class = class(labels);
  labels = full(double(labels));
  samples = sparse(double(samples));

  if options.n_folds > 1
    % Cross validation to find the best training params.
    accuracies = zeros(numel(options.c_range), ...
                       numel(options.eps_range), ...
                       numel(options.beta_range));
    for i = 1:numel(options.c_range)
      for j = 1:numel(options.eps_range)
        for k = 1:numel(options.beta_range)
          logger('C = %g, eps = %g, beta = %g', ...
                 options.c_range(i), ...
                 options.eps_range(j), ...
                 options.beta_range(k));
          liblinear_options = sprintf('-s %d -v %d -c %g -e %g%s%s',...
                                      options.solvers.(options.solver), ...
                                      options.n_folds, ...
                                      options.c_range(i), ...
                                      options.eps_range(j), ...
                                      weights_option(labels, ...
                                                     options.beta_range(k)),...
                                      repmat(' -q', 1, options.quiet));
          accuracies(i, j, k) = liblinear.train(labels,...
                                                samples,...
                                                liblinear_options);
        end
      end
    end
    index = find(accuracies(:) == max(accuracies(:)), 1);
    [ind1, ind2, ind3] = ind2sub(size(accuracies), index);
    best_c = options.c_range(ind1);
    best_eps = options.eps_range(ind2);
    best_beta = options.beta_range(ind3);
    logger('Best C = %g, eps = %g, beta = %g', best_c, best_eps, best_beta);
  else
    best_c = options.c_range(1);
    best_eps = options.eps_range(1);
    best_beta = options.beta_range(1);
  end
  
  % Train a model.
  liblinear_options = sprintf('-s %d -c %g -e %g%s%s', ...
                              options.solvers.(options.solver), ...
                              best_c, ...
                              best_eps, ...
                              weights_option(labels, best_beta),...
                              repmat(' -q', 1, options.quiet));
  classifier.model = liblinear.train(labels,...
                                     samples,...
                                     liblinear_options);

  % Reorder labels.
  if numel(classifier.model.Label) == 2
    % Assume positive is the larger label. Reorder to [positive, negative].
    if classifier.model.Label(1) > classifier.model.Label(2)
      classifier.model.w = -classifier.model.w;
      classifier.model.Label = flipud(classifier.model.Label);
    end
    classifier.model.w = classifier.model.w(:);
  else
    [classifier.model.Label, order] = sort(classifier.model.Label);
    classifier.model.w = -classifier.model.w(order, :)';
  end
  classifier.model.Label = feval(label_class, classifier.model.Label);
  
end

function [samples, normalizer] = train_normalizer(samples)
%TRAIN_NORMALIZER

  normalizer.mu = mean(samples, 1);
  normalizer.sigma = 3 * std(samples, [], 1);
  normalizer.sigma(normalizer.sigma <= 1e-6) = 1;
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

function string = weights_option(labels, beta)
%WEIGHTS_STRING
  [unique_labels, ~, index] = unique(labels);
  histogram = accumarray(index, 1, size(unique_labels));
  weights = histogram .^ beta;
  weights = numel(labels) * weights ./ sum(weights .* histogram);
  string = sprintf(' -w%d %g', [unique_labels(:)';weights(:)']);
end
