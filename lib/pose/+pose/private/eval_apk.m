function [apk prec rec] = eval_apk(det, gt, thresh)
% Evaluate the average precision of keypoints.
% Input:
%   det: 
%     det(n).point: detected keypoints for the n-th image. It is a 3d matrix
%										with size num_keypoints * 2 * num_detectedpersons.
%     det(n).score: detection confidence scores for the n-th image. It is a 
%										vector with length num_persons.
%   gt:
%     gt(n).point: ground truth keypoints for the n-th image. It is a 3d matrix 
%									 with size num_keypoints * 2 * num_groundtruthpersons.
%     gt(n).scale: scales for persons in the n-th image, which is also the radius
%									 for considering a correct keypoint. It is a vector with length
%									 num_groundtruthpersons.

if nargin < 3
  thresh = 0.1;
end

assert(numel(det) == numel(gt));

% Compute the scale of the ground truths
for n = 1:numel(gt)
  gt(n).scale = max(max(gt(n).point, [], 1) - min(gt(n).point, [], 1) + 1, [], 2);
  gt(n).scale = squeeze(gt(n).scale);
end

% Count the total number of detections
numdet = 0;
for n = 1:numel(det)
  numdet = numdet + size(det(n).point, 3);
end

% Count the total number of ground truths 
numgt = 0;
for n = 1:numel(gt)
	numgt = numgt + size(gt(n).point, 3);
end

% Count the number of parts
numparts = size(gt(1).point, 1);

% Organize all the detections
ca = struct('point', cell(1,numdet), 'fr', cell(1,numdet), 'score', cell(1,numdet));
cnt = 0;
for n = 1:numel(det)
	for i = 1:size(det(n).point, 3)
		cnt = cnt + 1;
		ca(cnt).point = det(n).point(:,:,i);
		ca(cnt).fr = n;
		ca(cnt).score = det(n).score(i);
	end
end

% Sort detection from high score to low score
[tmp_, I] = sort(cat(1, ca.score), 'descend');
ca = ca(I);

% Compute precision redetll and average precision
apk = zeros(1, numparts);
prec = cell(1, numparts);
rec = cell(1, numparts);
for p = 1:numparts
  % Store detection flag for computing true / false positives
  for i = 1:numel(gt)
    gt(i).isdet = zeros(1, size(gt(i).point, 3));
  end
  
  tp = zeros(numdet,1);
  fp = zeros(numdet,1);
  for n = 1:numdet
    i = ca(n).fr; % Get the image number for n-th detection
    if isempty(gt(i).point)  % If no positive instance in the image.
      fp(n) = 1; % This detection is a false positive.
      continue;
    end

    % Compute distance between detected keypoint and ground truth keypoints.
    point = repmat(ca(n).point(p,:), [1 size(gt(i).point, 3)]);
    dist = sqrt(sum((point - squeeze(gt(i).point(p,:,:))).^2, 2));
    dist = dist ./ gt(i).scale;

    [distmin jmin] = min(dist);
    if gt(i).isdet(jmin)
      % If this ground truth is already claimed by a higher score detection
      fp(n) = 1;
    elseif distmin <= thresh
      tp(n) = 1;
      gt(i).isdet(jmin) = 1;
    else
      fp(n) = 1;
    end
  end

  fp = cumsum(fp);
  tp = cumsum(tp);
  rec{p} = tp ./ numgt;
  prec{p} = tp ./ (fp + tp);

  apk(p) = VOCap(rec{p}, prec{p});
end
