function [labels, probabilities] = predict(classifier, samples, varargin)
%PREDICT Predict labels with the trained linear model.

  % Normalize features.
  samples = bsxfun(@minus, samples, classifier.normalizer.mu);
  samples = bsxfun(@rdivide, samples, classifier.normalizer.sigma);
  samples = expand_feature(samples, classifier.feature_order,...
                           'Independent', classifier.feature_independent);
  labels = zeros(size(samples,1), 1);
  [labels, acc, probabilities] = libsvm.svmpredict(labels, ...
                                                   samples, ...
                                                   classifier.model, ...
                                                   '-b 1 -q');
  if classifier.model.nr_class == 2 && ...
      all(unique(classifier.model.Label(:)) == [0;1])
    probabilities = probabilities(:, classifier.model.Label == 1);
  else
    [~, order] = sort(classifier.model.Labels);
    probabilities = probabilities(:, order);
  end
%   % Compute logistic regression.
%   probabilities = 1 ./ (1 + exp(samples * classifier.model.w));
%   if size(probabilities, 2) == 1
%     labels = classifier.model.Label((probabilities >= 0.5) + 1);
%   else
%     [~, best_label_index] = max(probabilities, [], 2);
%     labels = classifier.model.Label(best_label_index);
%   end

end

