function [retrieved_ids, tag_scores] = query_knn(config, samples)
%QUERY_KNN Retrieve nearest neighbors.
  queries = cat(1, samples.(config.input));
  [index, distances] = vl_kdtreequery(config.kdtree, ...
                                      config.descriptors, ...
                                      single(queries'), ...
                                      'NUMNEIGHBORS', config.num_neighbors);
  weights = 1 ./ (1 + distances);
  weights = bsxfun(@rdivide, weights, sum(weights, 1))';
  retrieved_ids = config.sample_ids(index)';
  tag_scores = zeros(numel(samples), numel(config.tags));
  for i = 1:numel(samples)
    tag_scores(i,:) = double(weights(i,:)) * ...
                      double(full(config.taggings(index(:,i), :)));
  end
end