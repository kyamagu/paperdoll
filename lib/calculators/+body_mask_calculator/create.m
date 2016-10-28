function config = create( varargin )
%CREATE Create a new calculator configuration.

  config = struct( ...
    'name', 'body_mask_calculator', ...
    'input_image', 'rgb', ...
    'input_pose',  'normal_pose', ...
    'output', 'body_mask' ...
    );
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'InputImage', config.input_image = varargin{i+1};
      case 'InputPose', config.input_pose = varargin{i+1};
      case 'Output', config.output = varargin{i+1};
    end
  end

end

