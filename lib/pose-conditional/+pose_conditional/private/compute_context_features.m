function features = compute_context_features(context, model)
%COMPUTE_CONTEXT_FEATURES Compute the context feature for pose estimator.
%     features = compute_context_features(context, model)
%
%  context: M-by-N array of per-pixel context labels.
%  model: struct with context_model field that defines labels.
  if nnz(model.context_model) == 0
    features = [];
    return;
  end

  % Split context map into blocks
  sbin = model.sbin;
  num_columns = repmat(sbin, 1, floor((size(context, 2) - 1) / sbin + 1));
  num_rows = repmat(sbin, 1, floor((size(context, 1) - 1) / sbin + 1));
  num_columns(end) = mod(size(context, 2) - 1, sbin) + 1;
  num_rows(end) = mod(size(context, 1) - 1, sbin) + 1;

  % Map input labels to index.
  valid_index = 0 < context & context <= numel(model.context_model);
  context(valid_index) = model.context_model(context(valid_index));
  context_c = mat2cell(context, num_rows, num_columns);
  num_labels = nnz(model.context_model);

  % Calculate histograms for each
  block_histograms = zeros(numel(context_c), num_labels);
  for i = 1:numel(context_c)
    values = context_c{i};
    values = values(values ~= 0); % Remove zero.
    if ~isempty(values)
      block_histograms(i,:) = accumarray(values(:), 1, [num_labels, 1])';
    end
  end
  block_histograms = reshape(block_histograms, ...
                             [size(context_c), num_labels]);

  % Sum up neighboring 4 blocks
  out_h = max(round(size(context, 1) / sbin) - 2, 0);
  out_w = max(round(size(context, 2) / sbin) - 2, 0);
  features = zeros(out_h, out_w, num_labels);
  for j = 1:size(features, 1)
    for i = 1:size(features, 2)
      h = block_histograms(j,i,:) + ...
          block_histograms(j+1,i,:) + ...
          block_histograms(j,i+1,:) + ...
          block_histograms(j+1,i+1,:);
      sum_h = sum(h(:));
      sum_h(sum_h == 0) = 1;
      features(j,i,:) = h(:) ./ sum_h;
    end
  end

end
