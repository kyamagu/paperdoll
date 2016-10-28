function output = encode_3d_array(input)
%ENCODE_3D_ARRAY Encode numeric 3D array.
%
%    output = encode_3d_array(input)
%
  assert(ndims(input) <= 3);
  output = cellfun(@encode_2d_array, num2cell(input, [1,2]));
  output = output(:)';
end

function output = encode_2d_array(input)
%ENCODE_2D_ARRAY Encode numeric 2D array.
  encodefun = @im2uint16;
  if isa(input, 'uint8'), encodefun = @(x)x; end
  array = double(input);
  min_value = min(array(:));
  max_value = max(array(:));
  scale = (max_value - min_value);
  if scale == 0, scale = 1; end
  output = struct(...
    'class', class(input),...
    'scale', scale,...
    'bias', min_value,...
    'data', imencode(encodefun((array - min_value) / scale))...
    );
end