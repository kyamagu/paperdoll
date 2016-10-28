function logger( varargin )
%LOGGER Display log message.
%
%    logger(fmt, param1, param2, ...)
%    logger(true)
%    logger(false)
%
% LOGGER displays a log message using the printf arguments. LOGGER takes
% format string FMT followed by parameters for substituion.
%
% LOGGER can be turned on/off by passing scalar logical value. This is
% useful in controling verbosity of the display text.
%
% See also fprintf

  persistent enabled;
  if isempty(enabled)
    enabled = true;
  end
  if nargin == 1 && islogical(varargin{1}) && isscalar(varargin{1})
    enabled = varargin{1};
  elseif enabled
    fprintf('[%s] ', datestr(now));
    fprintf(varargin{:});
    fprintf('\n');
  end

end
