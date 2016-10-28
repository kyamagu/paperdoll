function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = true;
  %ENCODE = true;
  INTERPOLATION_METHOD = 'Nearest';
  BORDER_VALUE = 1;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      %case 'Encode', ENCODE = varargin{i+1};
      case 'InverseWarpInterpolation', INTERPOLATION_METHOD = varargin{i+1};
      case 'InverseWarpBorderValue', BORDER_VALUE = varargin{i+1};
    end
  end
  
  % Quit if already there.
  if ~FORCE && all(cellfun(@(x)isfield(samples, x),config.output))
   return
  end
  
  % Resolve dependency.
  assert(isfield(samples, config.input_pose));
  for i = 1:numel(config.input_image)
    assert(isfield(samples, config.input_image{i}));
  end
  
  % Compute normalized image and pose.
  for i = 1:numel(samples)
    pose_struct = samples(i).(config.input_pose);
    if isnumeric(pose_struct)
      pose_struct = pose.PARSE_from_UCI(pose.box2point(pose_struct(1,:)));
    end
    image_size = samples(i).(config.input_image_size);
    bounding_box = get_bounding_box(pose_struct, image_size);
    for j = 1:numel(config.input_image)
      input_image = imread_or_decode(samples(i).(config.input_image{j}), 'png');
      warped_image = warp_image(input_image, ...
                                bounding_box, ...
                                image_size, ...
                                config.padding, ...
                                INTERPOLATION_METHOD, ...
                                BORDER_VALUE);
      warped_image = imencode(warped_image);
      samples(i).(config.output{j}) = warped_image;
    end
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

function warped_image = warp_image(im, box, frame_size, padding, interpolation_method, border_value)
%NORMALIZE_BOUNDING_BOX Align the size of bounding box.
  % Get the original transformation.
  image_size = size(im);
  sx = (box(3) - box(1)) / (image_size(2) - 2*padding);
  sy = (box(4) - box(2)) / (image_size(1) - 2*padding);
  tx = box(1) - sx * padding;
  ty = box(2) - sy * padding;
  transform = [sx, 0, tx; 0, sy, ty;];
  % Warp
  destination_size = frame_size;
  warped_image = cv.warpAffine(im, transform, ...
                               'Interpolation', interpolation_method,...
                               'WarpInverse', false,...
                               'BorderType', 'Constant',...
                               'BorderValue', border_value,...
                               'DSize', fliplr(destination_size));
end
