function config = create( varargin )
%CREATE Create a new calculator configuration.

  config = struct(...
    'name', 'dense_hog_calculator', ...
    'input', 'image', ...
    'output', 'dense_hog', ...
    'window', 8 ...
    );
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Input', config.input = varargin{i+1};
      case 'Output', config.output = varargin{i+1};
      case 'Window', config.window = varargin{i+1};
    end
  end

end

