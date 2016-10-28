function show_3d_array( input, varargin )
%SHOW_3D_ARRAY Show a 3D array.

  assert(isnumeric(input));
  siz = size(input);
  input = double(input(:,:,:));
  data = reshape(input, [siz(1:2), 1, repmat(siz(3:end), 1, numel(siz)>2)]);
  for i = 1:size(data, 4)
    x = data(:,:,1,i);
    min_x = min(x(:));
    max_x = max(x(:));
    data(:,:,1,i) = (data(:,:,1,i) - min_x) / (max_x - min_x);
  end
  montage(data, varargin{:});

end

