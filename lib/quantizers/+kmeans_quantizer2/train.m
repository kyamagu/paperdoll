function [model, projections] = train(samples, varargin)
%TRAIN Train a K-means quantizer.

  % Use (log(#SAMPLES + 1) * 4 * sqrt(#DIMS)) as default.
  NUM_CLUSTERS = round(log(size(samples, 1) + 1) * 4 * sqrt(size(samples, 2)));
  NORMALIZE = false;
  mark_delete = false(size(varargin));
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'NumClusters'
        NUM_CLUSTERS = varargin{i+1};
        mark_delete(i:i+1) = true;
      case 'Normalize'
        NORMALIZE = varargin{i+1};
        mark_delete(i:i+1) = true;
    end
  end
  varargin(mark_delete) = [];

  % Check if the input is row vectors.
  assert(isnumeric(samples));
  if ndims(samples) > 2
    siz = size(samples);
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end

  assert(isnumeric(samples));
  NUM_CLUSTERS = min(size(samples, 1), NUM_CLUSTERS);
  logger('kmeans_quantizer2: computing %d clusters for %d samples.', ...
         NUM_CLUSTERS, size(samples, 1));
  model.name = 'kmeans_quantizer2';
  
  if NORMALIZE
    [samples, model.mu, model.sigma] = zscore(samples);
  end
  
  if size(samples, 1) == NUM_CLUSTERS
    model.centroids = single(samples');
  else
    model.centroids = vl_kmeans(single(samples'), NUM_CLUSTERS, 'Verbose');
  end
  model.kdtree = vl_kdtreebuild(model.centroids);
  if nargout > 1
    projections = kmeans_quantizer2.project(model, samples, varargin{:});
  end

end

