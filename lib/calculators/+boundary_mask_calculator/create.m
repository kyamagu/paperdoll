function config = create( varargin )
%CREATE Create a new calculator configuration.

  config = struct( ...
    'name', 'boundary_mask_calculator', ...
    'input_image', 'normal_image', ...
    'output', 'boundary_mask' ...
    );
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'InputImage', config.input_image = varargin{i+1};
      case 'Output', config.output = varargin{i+1};
    end
  end

end

