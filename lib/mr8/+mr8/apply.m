function output = apply(input)
%APPLY Apply MR8 filterbanks to an image.

  input_size = size(input);
  if numel(input_size)>2, input = rgb2gray(input); end
  padded_input = padarray(input, [25, 25], 'replicate');
  output = MR8fast(padded_input);
  output = reshape(output', [input_size(1:2), 8]);

end
