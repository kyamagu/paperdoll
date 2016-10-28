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
    samples(i).(config.output) = compute_pose_map(size(input_image), ...
                                                  input_pose);
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end

function map = compute_pose_map(image_size, parse_pose)
%COMPUTE_POSE_MAP Compute a negative log-distance map from each pose joint.
  map = zeros(image_size(1), image_size(2), size(parse_pose.point, 1));
  [X, Y] = meshgrid(1:image_size(2), 1:image_size(1));
  for i = 1:size(parse_pose.point, 1)
    point = parse_pose.point(i,:);
    map(:,:,i) = -log((X - point(1)).^2 + (Y - point(2)).^2 + 1);
  end

%   map = zeros(image_size(1), image_size(2), 2*size(parse_pose.point, 1), 'single');
%   [X, Y] = meshgrid(1:image_size(2), 1:image_size(1));
%   for i = 1:size(parse_pose.point, 1)
%     point = parse_pose.point(i,:);
%     relative_X = X - point(1);
%     relative_Y = Y - point(2);
%     map(:,:,2*i-1) = relative_X; % sign(relative_X) .* log(relative_X.^2 + 1);
%     map(:,:,2*i  ) = relative_Y; % sign(relative_Y) .* log(relative_Y.^2 + 1);
%   end

  dmap = ones(image_size(1), image_size(2), 'uint8');
  links = pose.PARSE_definition();
  for i = 1:size(links, 1)
    x1 = parse_pose.point(links(i, 1), :);
    x2 = parse_pose.point(links(i, 2), :);
    dmap = cv.line(dmap, x1 - 1, x2 - 1);
  end
  dmap = -log(single(cv.distanceTransform(dmap)) + 1);
  map = cat(3, map, dmap);
  
%   links = [pose.PARSE_definition(); 3, 13; 4, 13];
%   canvas = ones(image_size(1), image_size(2), 'uint8');
%   map = ones(image_size(1), image_size(2), size(links, 1), 'single');
%   for i = 1:size(links, 1)
%     x1 = parse_pose.point(links(i, 1), :);
%     x2 = parse_pose.point(links(i, 2), :);
%     distance_map = cv.distanceTransform(cv.line(canvas, x1-1, x2-1));
%     map(:,:,i) = -log(distance_map + 1);
%   end
end