function config = create(varargin)
%CREATE Create a new calculator configuration.

  config = struct( ...
    'name', 'normal_pose_calculator', ...
    'input_image', 'image',...
    'input_pose', 'pose',...
    'output_image', 'normal_image', ...
    'output_pose', 'normal_pose', ... % Original image size
    'output_image_size', 'image_size', ...
    'frame_size', [282, 122], ... % [564, 233] : Average from Fashionista
    'padding',    10 ...
  );
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'InputImage', config.input_image = varargin{i+1};
      case 'InputPose',  config.input_pose = varargin{i+1};
      case 'OutputImage', config.output_image = varargin{i+1};
      case 'OutputPose',  config.output_pose = varargin{i+1};
      case 'OutputImageSize', config.output_image_size = varargin{i+1};
      case 'FrameSize',  config.frame_size = varargin{i+1};
      case 'Padding',    config.padding = varargin{i+1};
    end
  end

end

