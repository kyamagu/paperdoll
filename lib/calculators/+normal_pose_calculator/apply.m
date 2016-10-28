function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = true;
  IMAGE_FORMAT = 'jpg';
  INTERPOLATION_METHOD = 'Linear';
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force',  FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
      case 'NormalPoseImageFormat', IMAGE_FORMAT = varargin{i+1};
      case 'NormalPoseInterpolation', INTERPOLATION_METHOD = varargin{i+1};
    end
  end
  
  % Quit if already there.
  if ~FORCE && isfield(samples, config.output_image) && ...
               isfield(samples, config.output_pose)
    return
  end
  
  % Resolve dependency.
  assert(isfield(samples, config.input_image));
  assert(isfield(samples, config.input_pose));
  
  % Compute normalized image and pose.
  [samples.(config.output_image)] = deal([]);
  [samples.(config.output_pose)] = deal([]);
  [samples.(config.output_image_size)] = deal([]);
  for i = 1:numel(samples)
    image_data = imread_or_decode(samples(i).(config.input_image), ...
                                  IMAGE_FORMAT);
    pose_struct = samples(i).(config.input_pose);
    if isnumeric(pose_struct)
      pose_struct = pose.PARSE_from_UCI(pose.box2point(pose_struct(1,:)));
    end
    image_size = size(image_data);
    bounding_box = get_bounding_box(pose_struct, image_size);
    [normal_image, transform] = normalize_image(image_data, ...
                                                bounding_box, ...
                                                config.frame_size, ...
                                                config.padding, ...
                                                INTERPOLATION_METHOD);
    normal_pose = transform_pose(pose_struct, transform);
    %if ENCODE
      normal_image = imencode(normal_image, IMAGE_FORMAT);
    %end
    samples(i).(config.output_image) = normal_image;
    samples(i).(config.output_pose) = normal_pose;
    samples(i).(config.output_image_size) = image_size(1:2);
  end

end

function box = get_bounding_box(pose_struct, siz)
%GET_BOUNDING_BOX Get a bounding box over the body.
  [uci_pose, pa] = pose.PARSE_to_UCI(pose_struct);
  boxes = pose.point2box(uci_pose, pa);
  box = [min([boxes.x1]), min([boxes.y1]), max([boxes.x2]), max([boxes.y2])];
  box(1:2) = max(box(1:2), 1);
  box(3) = min(box(3), siz(2));
  box(4) = min(box(4), siz(1));
end

function [normalized_image, transform] = ...
    normalize_image(im, box, frame_size, padding, interpolation_method)
%NORMALIZE_BOUNDING_BOX Align the size of bounding box.
  sx = (box(3) - box(1)) / frame_size(2);
  sy = (box(4) - box(2)) / frame_size(1);
  tx = box(1) - sx * padding;
  ty = box(2) - sy * padding;
  transform = [sx, 0, tx; 0, sy, ty;];
  destination_size = frame_size + 2 * padding;
  normalized_image = cv.warpAffine(im, transform, ...
                                   'Interpolation', interpolation_method,...
                                   'WarpInverse', true,...
                                   'BorderType', 'Replicate',...
                                   'DSize', fliplr(destination_size));
end

function parse_pose = transform_pose(parse_pose, transform)
%CONVERT_TO_POSE_STRUCT Convert the boxes to PARSE pose struct.
  X = [parse_pose.point, ones(size(parse_pose.point, 1), 1)];
  Y = X / [transform;0,0,1]';
  parse_pose.point = Y(:,1:2);
end