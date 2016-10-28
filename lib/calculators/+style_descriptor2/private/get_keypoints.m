function keypoints = get_keypoints( pose_struct )
%INTERPOLATE_POSE Interpolate the keypoints over the body.

  uci_pose = pose.PARSE_to_UCI(pose_struct);
  
  % Add torso keypoints, remove arm points.
  keypoints = [uci_pose.point; ...
               mean(uci_pose.point([8 20],:)); ...
               mean(uci_pose.point([9,21],:))];
  keypoints([4,6,16,18],:) = [];

end

