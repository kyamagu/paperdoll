function config = create( varargin )
%CREATE Create a new calculator configuration.

  config = struct( ...
    'name', 'pose_map_calculator', ...
    'input_image', 'image', ...
    'input_pose',  'pose', ...
    'output', 'pose_map' ...
    );
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'InputImage', config.input_image = varargin{i+1};
      case 'InputPose', config.input_pose = varargin{i+1};
      case 'Output', config.output = varargin{i+1};
    end
  end

end

