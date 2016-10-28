function pck = eval_pck(ca, gt, thresh)

if nargin < 3
  thresh = 0.1;
end

assert(numel(ca) == numel(gt));

% Compute the scale of the ground truths
for n = 1:length(gt)
  gt(n).scale = max(max(gt(n).point, [], 1) - min(gt(n).point, [], 1) + 1, [], 2);
  gt(n).scale = squeeze(gt(n).scale);
end

for n = 1:length(gt)
  dist = sqrt(sum((ca(n).point-gt(n).point).^2,2));
  tp(:,n) = dist <= thresh * gt(n).scale;
end

pck = mean(tp,2)';