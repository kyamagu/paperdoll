function projections = project(model, samples)
%APPLY Apply histogram projection.

  siz = size(samples);
  if numel(siz) > 2
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  assert(size(samples, 2) == size(model.ticks, 2));
  projections = cell(1, size(model.ticks, 2));
  for i = 1:size(model.ticks, 2)
    distances = pdist2(samples(:, i), model.ticks(:, i));
    min_dist = zeros(size(distances, 1), 2);
    min_index = zeros(size(distances, 1), 2);
    [min_dist(:,1), min_index(:,1)] = min(distances, [], 2);
    min_lindex = sub2ind(size(distances), 1:size(distances,1), min_index(:,1)');
    distances(min_lindex) = inf;
    [min_dist(:,2), min_index(:,2)] = min(distances, [], 2);
    min_dist(min_index(:,1) == 1 & ...
             min_dist(:,2) > model.stepsize(i), 1) = 0;
    min_dist(min_index(:,1) == size(model.ticks,1) & ...
             min_dist(:,2) > model.stepsize(i), 1) = 0;
    weights = bsxfun(@rdivide, fliplr(min_dist), sum(min_dist, 2));
    projections{i} = accumarray(...
        [repmat(1:size(distances, 1), 1, 2)', min_index(:)], ...
        weights(:), size(distances)...
        );
    assert(all(abs(sum(projections{i}, 2) - 1) < 1e-5));
  end
  projections = [projections{:}];

  if numel(siz) > 2
    projections = reshape(projections, [siz(1:2), size(projections, 2)]);
  end

end

