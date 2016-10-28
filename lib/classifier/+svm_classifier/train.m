function classifier = train(labels, samples, varargin)
%TRAIN Train a linear classifier using liblinear.

  types = struct('C_SVC',         0, ...
                 'nu_SVC',        1, ...
                 'one_class_SVM', 2, ...
                 'epsilon_SVR',   3, ...
                 'nu_SVR',        4);
  kernels = struct('linear',      0, ...
                   'polynomial',  1, ...
                   'rbf',         2, ...
                   'sigmoid',     3, ...
                   'precomputed', 4);
  n_folds = 3;
  c_range = 10.^(-1:1);
  gamma_range = 1 / size(samples, 2);
  feature_order = 2;
  feature_independent = true;
  weights = [];
  type = 'C_SVC';
  kernel = 'rbf';
  quiet = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'NumFolds', n_folds = varargin{i+1};
      case 'CRange', c_range = varargin{i+1};
      case 'GammaRange', gamma_range = varargin{i+1};
      case 'FeatureOrder', feature_order = varargin{i+1};
      case 'FeatureIndependent', feature_independent = varargin{i+1};
      case 'Type', type = varargin{i+1};
      case 'Kernel', kernel = varargin{i+1};
      case 'Weights', weights = varargin{i+1};
      case 'Quiet', quiet = varargin{i+1};
    end
  end
  logger(['Training a classifier: type = %s, kernel = %s, ' ...
         'n_folds = %d, order = %d, independent = %d'], ...
         type, ...
         kernel, ...
         n_folds, ...
         feature_order, ...
         feature_independent);

  % Normalize the feature representation.
  [normalized_samples, classifier.normalizer] = train_normalizer(samples);
  classifier.feature_order = feature_order;
  classifier.feature_independent = feature_independent;
  normalized_samples = expand_feature(normalized_samples, classifier.feature_order, ...
                                      'Independent', classifier.feature_independent);
  logger('samples = %d, features = %d', ...
         size(normalized_samples, 1), ...
         size(normalized_samples, 2));
  labels = full(double(labels));
  weights_option = weights_string(unique(labels), weights);
  normalized_samples = double(normalized_samples);

  if n_folds > 1
    % Cross validation to find the best training params.
    accuracies = zeros(numel(c_range), numel(gamma_range));
    for i = 1:numel(c_range)
      for j = 1:numel(gamma_range)
        logger('C = %g, gamma = %g', c_range(i), gamma_range(j));
        options = sprintf('-s %d -t %d -v %d -c %g -g %g%s%s',...
                          types.(type), ...
                          kernels.(kernel), ...
                          n_folds, ...
                          c_range(i), ...
                          gamma_range(j), ...
                          weights_option,...
                          repmat(' -q', 1, quiet));
        accuracies(i, j) = libsvm.svmtrain(labels,...
                                           normalized_samples,...
                                           options);
      end
    end
    index = find(accuracies(:) == max(accuracies(:)), 1);
    [row, col] = ind2sub(size(accuracies), index);
    best_c = c_range(row);
    best_gamma = gamma_range(col);
    logger('Best C = %g, gamma = %g', best_c, best_gamma);
  else
    best_c = c_range(1);
    best_gamma = gamma_range(1);
  end
  
  % Train a model.
  options = sprintf('-s %d -t %d -b 1 -c %g -g %g%s%s', ...
                    types.(type), ...
                    kernels.(kernel), ...
                    best_c, ...
                    best_gamma, ...
                    weights_option,...
                    repmat(' -q', 1, quiet));
  classifier.model = libsvm.svmtrain(labels,...
                                     normalized_samples,...
                                     options);

%   % Reorder labels.
%   if numel(classifier.model.Label) == 2
%     % Assume positive is the larger label. Reorder to [positive, negative].
%     if classifier.model.Label(1) > classifier.model.Label(2)
%       classifier.model.w = -classifier.model.w;
%       classifier.model.Label = flipud(classifier.model.Label);
%     end
%     classifier.model.w = classifier.model.w(:);
%   else
%     [classifier.model.Label, order] = sort(classifier.model.Label);
%     classifier.model.w = -classifier.model.w(order, :)';
%   end
  
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

function string = weights_string(labels, weights)
%WEIGHTS_STRING
  if isempty(weights)
    string = '';
  else
    assert(numel(labels) == numel(weights));
    string = sprintf(' -w%d %g', [labels(:)';weights(:)']);
  end
end
