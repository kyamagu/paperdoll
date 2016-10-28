function predictions = predict(regressor, samples, varargin)
%PREDICT Predict labels with the trained linear model.

  if isfield(regressor, 'normalizer')
    samples = bsxfun(@minus, samples, regressor.normalizer.mu);
    samples = bsxfun(@rdivide, samples, regressor.normalizer.sigma);
  end
  samples = expand_feature(samples, regressor.feature_order,...
                           'Independent', regressor.feature_independent);
  predictions = samples * cat(2, regressor.model.w);

end

