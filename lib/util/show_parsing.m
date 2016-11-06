function show_parsing(rgb_image, labeling, labels)
%SHOW_PARSING Visualize semantic parsing.
  subplot(1, 2, 1);
  imshow(imread_or_decode(rgb_image, 'jpg'));
  subplot(1, 2, 2);
  if isvector(labeling)
    labeling = imdecode(labeling);
  end
  if size(labeling, 3) > 1
    [~, labeling] = max(labeling, [], 3);
  end
  [labeling, labels] = reorder_labels(uint8(labeling), labels);
  colors = [1,1,1;1,.75,.75;.2,.1,.1;hsv(numel(labels) - 3)];
  imshow(double(labeling), colors);
  colorbar('YTickLabel', labels, ...
           'YTick', (1:numel(labels)), ...
           'YTickMode', 'manual');
end

function [ordered_labeling, ordered_labels] = reorder_labels(labeling, labels)
%REORDER_LABELS
  reserved_labels = {'null', 'skin', 'hair'};
  ordered_labels = [reserved_labels(:); setdiff(labels(:), reserved_labels(:))];
  ordered_labeling = zeros(size(labeling), 'uint8');
  for i = 1:numel(labels)
    ordered_labeling(labeling == i) = find(strcmp(labels{i}, ordered_labels));
  end
  assert(all(ordered_labeling(:) ~= 0));
end
