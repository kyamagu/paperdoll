function [labeling, negative_log_likelihood] = apply( unary_probabilities, input_image, varargin )
%APPLY Apply grabcut-style smoothing.

  BETA = [];
  GAMMA = 10;
  V_smooth = [];
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Beta', BETA = varargin{i+1};
      case 'Gamma', GAMMA = varargin{i+1};
      case 'SmoothCost', V_smooth = varargin{i+1};
    end
  end

  image_size = size(input_image);
  num_sites = image_size(1) * image_size(2);
  
  % Prepare costs.
  unary_probabilities = reshape(unary_probabilities, ...
                                [num_sites, size(unary_probabilities, 3)]);
  valid_labels = find(max(unary_probabilities, [], 1) ~= 0);
  num_labels = numel(valid_labels);
  U = -log(unary_probabilities(:, valid_labels));
  U = min(U, 10000000 - 1); % Limit to prevent integer overflow.
  if isempty(V_smooth)
    V_smooth = 1 - eye(num_labels);
  else
    V_smooth = min(V_smooth(valid_labels, valid_labels), 10000000 - 1);
  end
  
  features = reshape(im2double(input_image), [num_sites, image_size(3)]);
  [J, I] = ndgrid(1:image_size(1), 1:image_size(2));
  Y1 = sub2ind(image_size(1:2), J(1:end-1,:), I(1:end-1,:));
  Y2 = sub2ind(image_size(1:2), J(2:end  ,:), I(2:end,  :));
  X1 = sub2ind(image_size(1:2), J(:,1:end-1), I(:,1:end-1));
  X2 = sub2ind(image_size(1:2), J(:,2:end  ), I(:,2:end  ));
  square_feature_diff = sum([features(X1(:), :) - features(X2(:), :);...
                             features(Y1(:), :) - features(Y2(:), :)].^2, 2);
  if isempty(BETA)
    BETA = 1 ./ (2 * mean(square_feature_diff));
  end
  W = GAMMA * exp(-BETA * square_feature_diff);
  V_neigh = sparse([X1(:);Y1(:)], [X2(:);Y2(:)], W(:), num_sites, num_sites);
  
  gco_object = GCO_Create(num_sites, num_labels);
  try
    GCO_SetDataCost(gco_object, int32(U'));
    GCO_SetSmoothCost(gco_object, int32(V_smooth));
    GCO_SetNeighbors(gco_object, round(V_neigh));
    %GCO_Expansion(gco_object);
    GCO_Swap(gco_object);
    labeling = GCO_GetLabeling(gco_object);
    labeling = reshape(double(valid_labels(labeling)), image_size(1:2));
    if nargout > 1
      negative_log_likelihood = GCO_ComputeEnergy(gco_object);
    end
  catch e
    GCO_Delete(gco_object);
    rethrow(e);
  end
  GCO_Delete(gco_object);

end

