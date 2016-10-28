function output = decode_3d_array(input)
%DECODE_3D_ARRAY Decode numeric 3D array.
%
%    output = decode_3d_array(input)
%
  output = arrayfun(@decode_2d_array, input, 'UniformOutput', false);
  output = cat(3, output{:});
end

function output = decode_2d_array(input)
%DECODE_2D_ARRAY Decode numeric 2D array.
  output = im2double(imdecode(input.data)) * input.scale + input.bias;
  output = feval(input.class, output);
end