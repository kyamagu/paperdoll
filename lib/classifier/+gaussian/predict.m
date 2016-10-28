function [labels, probabilities] = predict(classifier, samples, varargin)
%PREDICT Predict labels with the trained Gaussian.

  probabilities = zeros(size(samples, 1), numel(classifier.labels));
  for i = 1:numel(classifier.labels)
    normal_samples = bsxfun(@minus, samples, classifier.mu(i,:));
    probabilities(:, i) = exp(-0.5 * ...
                              sum((normal_samples / classifier.sigma(:,:,i)) .* ...
                                  normal_samples, 2) +...
                              classifier.log_coeff(i) ...
                              );
  end
  [~, labels] = max(probabilities, [], 2);
  labels = classifier.labels(labels(:));
%   if numel(classifier.labels) > 1
%     probabilities = bsxfun(@rdivide, probabilities, sum(probabilities, 2));
%   end

end

