function det = PARSE_transback(boxes)

% -------------------
% Generate candidate keypoint locations
% Our model produce 26 keypoint locations including joints and their middle points
% But for PARSE evaluation, we will only use the original 14 joints
I = [1  2  3  4  5  6  7  8  9  10 11 12 13 14];
J = [14 12 10 22 24 26 7  5  3  15 17 19 2  1];
A = [1  1  1  1  1  1  1  1  1  1  1  1  1  1];
Transback = full(sparse(I,J,A,14,26));

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
    det(n).point(:,:,i) = Transback * [bx(i,:)' by(i,:)'];
    det(n).score(i) = box(i, end);
  end
end