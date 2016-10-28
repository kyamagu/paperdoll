function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  BORDER_WIDTH = 5;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
      case 'BoundaryBorderWidth', BORDER_WIDTH = varargin{i+1};
    end
  end
  
  % Quit if already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Resolve dependency.
  assert(isfield(samples, config.input_image));
  
  % Compute normalized image and pose.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input_image);
    input_image = imread_or_decode(sample.(config.input_image), 'jpg');
    samples(i).(config.output) = draw_boundary_mask(size(input_image), BORDER_WIDTH);
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end

function map = draw_boundary_mask(image_size, border_width)
%DRAW_BOUNDARY_MASK Draw a boundary feature.
  map = ones([image_size(1:2), 2]);
  map(1:end, [1:border_width,end-border_width:end], 1) = 0;
  map([1:border_width,end-border_width:end], 1:end, 2) = 0;
  map(:,:,1) = -log(1 + cv.distanceTransform(uint8(map(:,:,1))));
  map(:,:,2) = -log(1 + cv.distanceTransform(uint8(map(:,:,2))));
%   map = zeros([image_size(1:2), 2]);
%   map(1:end, [1:border_width,end-border_width:end], 1) = 1;
%   map([1:border_width,end-border_width:end], 1:end, 2) = 1;
end