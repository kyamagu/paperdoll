function [labels, probabilities] = predict(classifier, samples, varargin)
%PREDICT Predict labels with the trained linear model.

  % Normalize features.
  if isfield(classifier, 'normalizer')
    samples = bsxfun(@minus, double(samples), double(classifier.normalizer.mu)) * ...
              diag(sparse(1 ./ double(classifier.normalizer.sigma)));
  end
  samples = expand_feature(samples, classifier.feature_order,...
                           'Independent', classifier.feature_independent);
  % Compute logistic regression.
  probabilities = 1 ./ (1 + exp(samples * classifier.model.w));
  if size(probabilities, 2) == 1
    labels = classifier.model.Label((probabilities >= 0.5) + 1);
    if ~islogical(labels)
      probabilities = [1-probabilities, probabilities];
    end
  else
    [~, best_label_index] = max(probabilities, [], 2);
    labels = classifier.model.Label(best_label_index);
  end

end

