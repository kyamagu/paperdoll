function config = create( varargin )
%CREATE Create a new calculator configuration.

  config = cell(1, floor(numel(varargin)/2));
  for i = 1:2:numel(varargin)
    creator = str2func([varargin{i}, '.create']);
    config{(i+1)/2} = creator(varargin{i+1}{:});
  end

end

