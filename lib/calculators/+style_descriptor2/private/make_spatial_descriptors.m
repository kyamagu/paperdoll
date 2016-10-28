function descriptors = make_spatial_descriptors(dense_feature, keypoints, poolfun, varargin)
%MAKE_SPATIAL_DESCRIPTORS Describe dense feature map with descriptors at keypoints.
%
% ## Input
%    dense_feature: M-by-N-by-d numeric array of 2D d-dimensional feature map.
%        keypoints: R-by-2 row vectors of (x,y) coordinates at which to extract
%                   descriptors.
%          poolfun: Function to summarize each cell. The input must be a
%                   function handle that takes m-by-n-by-d dense features and
%                   return 1-by-K dimensional vector.
%
% ## Output
%      descriptors: R-by-K dimensional vectors of extracted descriptors.
%
% ## Options
%         CellSize: Size of each cell in pixels. For example, [8, 8] means
%                   8-by-8 sized patch would be summarized for each cell.
%         GridSize: Arrangement of cell grid. For example, [4, 4] would result
%                   in 4-by-4 spatial grid of cells to be used for descriptors.
%                   The total pixel size of the patch would be
%                   CellSize .* GridSize.
%

  CELL_SIZE = [8, 8];  % Size of each cell in pixels.
  GRID_SIZE = [4, 4];  % Size of cells.
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'CellSize', CELL_SIZE = varargin{i+1};
      case 'GridSize', GRID_SIZE = varargin{i+1};
    end
  end
  
  patch_size = CELL_SIZE .* GRID_SIZE;
  image_size = size(dense_feature);
  extra_pad = max(max(-min(keypoints, [], 1) + 2, 0),...
                  max(max(keypoints, [], 1) - image_size([2,1]) + 1, 0));
  pad_size = ceil(patch_size + extra_pad([2,1]));
  dense_feature = padarray(dense_feature, [pad_size, 0], 'replicate', 'symmetric');
  keypoints = bsxfun(@plus, round(keypoints), pad_size);
  descriptors = cell(size(keypoints, 1), 1);
  for i = 1:size(keypoints, 1)
    keypoint = keypoints(i,:);
    xrange = keypoint(1)-patch_size(1)/2+1:keypoint(1)+patch_size(1)/2;
    yrange = keypoint(2)-patch_size(2)/2+1:keypoint(2)+patch_size(2)/2;
    feature_patch = dense_feature(yrange, xrange, :);
    split_patch = mat2cell(feature_patch, ...
                           repmat(CELL_SIZE(1), 1, GRID_SIZE(1)),...
                           repmat(CELL_SIZE(2), 1, GRID_SIZE(2)),...
                           size(feature_patch, 3));
    feature_cells = cellfun(poolfun, split_patch(:), 'UniformOutput', false);
    descriptors{i} = [feature_cells{:}];
  end
  descriptors = cat(1, descriptors{:});

end