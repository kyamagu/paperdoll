function config = create( varargin )
%CREATE Create a new calculator configuration.

  config = struct(...
    'name', 'mr8_calculator', ...
    'input', 'image', ...
    'output', 'mr8' ...
    );
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Input', config.input = varargin{i+1};
      case 'Output', config.output = varargin{i+1};
    end
  end

end

