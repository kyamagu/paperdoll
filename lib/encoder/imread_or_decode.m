function output = imread_or_decode( input, varargin )
%IMDECODE Decompress image data in the specified format
%
%    output = imencode(input)
%    output = imencode(input, fmt)
%
% IMDECODE decompresses binary array INPUT into image data OUTPUT using
% specified format FMT. FMT is a name of image file extension that is
% recognized by IMFORMATS function, such as 'jpg' or 'png'. When FMT is
% omitted, 'png' is used as default.
%
% See also imencode imformats imread

if isa(input, 'uint8') && isvector(input)
  output = imdecode(input, varargin{:});
elseif ischar(input)
  output = imread(input, varargin{:});
elseif isnumeric(input)
  output = input;
else
  error('Invalid input: %s.', class(input));
end

end

