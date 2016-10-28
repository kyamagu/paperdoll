function projections = project(model, samples, varargin)
%APPLY Apply K-means projection.

  NUM_ASSIGNMENTS = 5;
  OUTPUT_INDICES = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'NumAssignments', NUM_ASSIGNMENTS = varargin{i+1};
      case 'OutputIndices', OUTPUT_INDICES = varargin{i+1};
    end
  end

  siz = size(samples);
  if numel(siz) > 2
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  
  if isfield(model, 'mu') && isfield(model, 'sigma')
    samples = bsxfun(@minus, samples, model.mu);
    samples = bsxfun(@rdivide, samples, model.sigma);
  end
  
  if OUTPUT_INDICES
    index = vl_kdtreequery(model.kdtree, ...
                           model.centroids, ...
                           single(samples)');
    projections = double(index(:));
  else
    [index, distances] = vl_kdtreequery(model.kdtree, ...
                                        model.centroids, ...
                                        single(samples)',...
                                        'NUMNEIGHBORS', NUM_ASSIGNMENTS);
    distances = exp(-double(distances));
    weights = bsxfun(@rdivide, distances, sum(distances, 1));
    row_index = repmat(1:size(index,2), size(index, 1), 1);
    projections = accumarray([row_index(:), index(:)],...
                             weights(:),...
                             [size(samples, 1), size(model.centroids, 2)]);
  end

  if numel(siz) > 2
    projections = reshape(projections, [siz(1:2), size(projections, 2)]);
  end

end

