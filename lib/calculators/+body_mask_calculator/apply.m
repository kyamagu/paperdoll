function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
    end
  end
  
  % Quit if already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Resolve dependency.
  assert(isfield(samples, config.input_image));
  assert(isfield(samples, config.input_pose));
  
  % Compute normalized image and pose.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input_image);
    input_image = imread_or_decode(sample.(config.input_image), 'jpg');
    input_pose = sample.(config.input_pose);
    if isnumeric(input_pose)
      input_pose = pose.PARSE_from_UCI(pose.box2point(input_pose));
    end
    samples(i).(config.output) = draw_torso_map(size(input_image), ...
                                                 input_pose);
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end

function map = draw_torso_map(image_size, parse_pose)
%COMPUTE_POSE_MAP Draw an indicator of torso.
  map = zeros(image_size(1:2), 'uint8');
  points = parse_pose.point([3,4,10,13,9], :);
  map = roipoly(map, points(:,1), points(:,2));

  % Compute distance
  map = log(1 + cv.distanceTransform(map));
end