function det = box2point(boxes)
%BOX_TO_POINT Convert raw DPM results to keypoints and score

  if ~iscell(boxes), boxes = {boxes}; end
  det = struct('point', cell(1, numel(boxes)), 'score', cell(1, numel(boxes)));
  for n = 1:length(boxes)
    if isempty(boxes{n}), continue, end;
    box = boxes{n};
    b = box(:, 1:floor(size(box, 2)/4)*4);
    b = reshape(b, size(b,1), 4, size(b,2)/4);
    b = permute(b,[1 3 2]);
    bx = .5*b(:,:,1) + .5*b(:,:,3);
    by = .5*b(:,:,2) + .5*b(:,:,4);
    for i = 1:size(b,1)
      det(n).point(:,:,i) = [bx(i,:)' by(i,:)'];
      det(n).score(i) = box(i, end);
    end
  end

end

