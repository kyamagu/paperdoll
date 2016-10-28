function feature_summary = pool(features)
%POOL Summarize the input features.

  siz = size(features);
  if numel(siz) > 2
    features = reshape(features, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  feature_summary = sparse([mean(features, 1), max(features, [], 1)]);

end

