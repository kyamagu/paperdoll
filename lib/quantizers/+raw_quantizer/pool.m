function feature_summary = pool(features)
%POOL Summarize the input features.

  siz = size(features);
  if numel(siz) > 2
    features = reshape(features, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  %feature_summary = mean(features, 1);
  feature_summary = [mean(features, 1), std(features, 0, 1)];
  %C = cov(features);
  %feature_summary = [mean(features, 1), C(tril(true(size(C))))'];

end

