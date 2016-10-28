function [config, samples] = train( config, samples, varargin )
%TRAIN Train a calculator configuration.

  % Fit the threshold value to the training samples.
  logger('Finding the best threshold for KNN@%d samples', ...
         config.num_neighbors);
  training_taggings = get_training_taggings(config, samples);
  [~, tag_scores] = query_knn(config, samples);
  config.threshold = find_best_threshold(config, ...
                                         training_taggings, ...
                                         tag_scores);

  if nargout > 1
    logger('Computing %s', config.output);
    samples = knn_retriever.apply(config, samples, varargin{:});
  end
end

function taggings = get_training_taggings(config, samples)
%GET_TRAINING_TAGGINGS Convert descriptors into sparse logical.
  taggings = false(numel(samples), numel(config.tags));
  for i = 1:numel(samples)
    sample = samples(i);
    tag_index = cellfun(@(x)find(strcmp(x, config.tags)), ...
                        sample.(config.annotation), ...
                        'UniformOutput', false);
    tag_index = [tag_index{~cellfun(@isempty, tag_index)}];
    taggings(i, tag_index) = true;
  end
end

function threshold = find_best_threshold(config, taggings, scores)
%FIND_BEST_THRESHOLD Find the best threshold value for KNN tag prediction.
  taggings = taggings(:);
  [sorted_scores, order] = sort(scores(:), 'descend');
  ordered_truth = taggings(order);
  tp = cumsum(ordered_truth);
  fn = tp(end) - cumsum(ordered_truth);
  %fp = cumsum(~ordered_truth);
  % Remove same-rankers.
  [unique_scores, index] = unique(sorted_scores, 'last');
  unique_scores = flipud(unique_scores);
  index = flipud(index);
  tp = tp(index);
  fn = fn(index);
  %fp = fp(index);
  % Find the threshold @ recall=0.5.
  recall = tp ./ (tp + fn);
  best_index = max(1, find(recall >= config.target_recall, 1) - 1);
  threshold = unique_scores(best_index);
  logger('Best threshold for recall@%g is %g', config.target_recall, threshold);
end