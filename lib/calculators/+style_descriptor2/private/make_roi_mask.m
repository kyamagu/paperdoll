function roi_mask = make_roi_mask(keypoints, image_size, patch_size)
%MAKE_ROI_MASK

  roi_mask = false(image_size(1:2));
  keypoints = round(keypoints);
  for i = 1:size(keypoints, 1)
    keypoint = keypoints(i,:);
    xrange = keypoint(1)-patch_size(1)/2+1:keypoint(1)+patch_size(1)/2;
    yrange = keypoint(2)-patch_size(2)/2+1:keypoint(2)+patch_size(2)/2;
    xrange = max(min(xrange, image_size(2)), 1);
    yrange = max(min(yrange, image_size(1)), 1);
    roi_mask(yrange(:), xrange(:)) = true;
  end

end

