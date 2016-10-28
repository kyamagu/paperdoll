function config = create( varargin )
%CREATE Create a new calculator configuration.

  config = struct(...
    'name',   'field_extractor', ...
    'output', {{}} ...
    );
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Output', config.output = varargin{i+1};
    end
  end

end

