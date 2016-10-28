function features = dense_hog(input_image, window)
%DENSE_HOG compute dense HOG features from an image.
%
%    features = dense_hog(input_image)
%    features = dense_hog(input_image, window)
%
% Matlab implementation of HOG feature used in VOC2011 object detector.
% This implementation allows descriptor extraction from every pixel rather
% than the fixed grid used in the original VOC implementation. That is, for
% the input image of size M-by-N-by-d, this function returns an M-by-N-by-31
% numeric array. FEATURES(i,j,:) corresponds to the HOG feature at pixel (i,j).
% WINDOW is the block size of histogram computation in pixels. It can be a
% scalar value for square block, or two-element vector for rectangular
% block. If skipped, the default value 4 is used.
%
% The resulting FEATURES contain 31-dimensional vector for each pixel. This
% is different from the original implementation which appends all-zero
% values at the 32nd dimension to be used as a boundary indicator. This
% implementation does not append the boundary indicator.
%
% To emulate the original HOG implementation, subsample the features at
% grid points, and append zeros at the end.
%
%    features = dense_hog(input_image, sbin);
%    features = features(sbin+1:sbin:end-sbin,...
%                        sbin+1:sbin:end-sbin,:);
%    features = cat(3, features, zeros(size(features,1), size(features,2));
%
% The function gives very similar result to the original implementation.
% However, due to the difference in numerical precision and image boundary
% handling, the result is not exactly the same.

% Kota Yamaguchi 2012

  orientations = 18; % Number of orientations in binning. must be even.
  if nargin < 2, window = 4; end
  if isscalar(window), window = repmat(window,1,2); end
  if ~isa(input_image,'double'), input_image = im2double(input_image); end

  % Compute color gradient by Sobel.
  dx = imfilter(input_image, [-1,0,1], 'same', 'replicate');
  dy = imfilter(input_image, [-1;0;1], 'same', 'replicate');
  % Pick the strongest channel.
  [max_magnitude, max_index] = max(dx.*dx + dy.*dy, [], 3);
  max_index = reshape(1:numel(max_index), size(max_index)) +...
                      numel(max_index)*(max_index-1);
  dx = dx(max_index);
  dy = dy(max_index);
  % Snap to one of the orientations.
  theta = reshape(2*(0:(orientations-1))/orientations*pi,[1,1,orientations]);
  inner_products = bsxfun(@times, dx, cos(theta)) +...
                   bsxfun(@times, dy, sin(theta));
  % Use the following for better compatibility
  %   cos_theta = [1.0000, 0.9397, 0.7660, 0.500, 0.1736, -0.1736, -0.5000, -0.7660, -0.9397];
  %   sin_theta = [0.0000, 0.3420, 0.6428, 0.8660, 0.9848, 0.9848, 0.8660, 0.6428, 0.3420];
  %   cos_theta = reshape([cos_theta,-cos_theta],[1,1,numel(cos_theta)*2]);
  %   sin_theta = reshape([sin_theta,-sin_theta],[1,1,numel(sin_theta)*2]);
  %   inner_products = bsxfun(@times, dx, cos_theta) +...
  %                    bsxfun(@times, dy, sin_theta);
  [max_response, max_index] = max(inner_products, [], 3);
  max_index = reshape(1:numel(max_index), size(max_index)) +...
                      numel(max_index)*(max_index-1);
  % Make oriented gradient maps.
  responses = zeros(size(inner_products));
  responses(max_index) = sqrt(max_magnitude(:));
  % Create a pixelwise histogram by 2D voting filter.
  votes = imfilter(responses, voting_kernel(window), 'same', 'replicate');
  % Compute energy in each block by summing over orientations.
  votes_sum = votes(:,:,1:orientations/2) + votes(:,:,orientations/2+1:end);
  votes_norm = sum(votes_sum.^2, 3);
  % Compute coefficients for 4 directions.
  coeffs = imfilter(votes_norm, block_kernel(window), 'full', 'replicate');
  coeffs = 1 ./ sqrt(coeffs + eps);
  coeff1 = coeffs(window(1)+1:end,  window(2)+1:end);
  coeff2 = coeffs(1:end-window(1),  window(2)+1:end);
  coeff3 = coeffs(window(1)+1:end,  1:end-window(2));
  coeff4 = coeffs(1:end-window(1),  1:end-window(2));
  % Contrast-sensitive features.
  h1 = min(bsxfun(@times, votes, coeff1), 0.2);
  h2 = min(bsxfun(@times, votes, coeff2), 0.2);
  h3 = min(bsxfun(@times, votes, coeff3), 0.2);
  h4 = min(bsxfun(@times, votes, coeff4), 0.2);
  cs_features = 0.5 * (h1 + h2 + h3 + h4);
  t1 = sum(h1, 3);
  t2 = sum(h2, 3);
  t3 = sum(h3, 3);
  t4 = sum(h4, 3);
  % Contrast-insensitive features.
  h1 = min(bsxfun(@times, votes_sum, coeff1), 0.2);
  h2 = min(bsxfun(@times, votes_sum, coeff2), 0.2);
  h3 = min(bsxfun(@times, votes_sum, coeff3), 0.2);
  h4 = min(bsxfun(@times, votes_sum, coeff4), 0.2);
  ci_features = 0.5 * (h1 + h2 + h3 + h4);
  % Texture features. (I have no idea why this is 0.2357.)
  t_features = 0.2357 * cat(3, t1, t2, t3, t4);
  % Format the result.
  features = cat(3, cs_features, ci_features, t_features);
end

function kern = voting_kernel(window)
%VOTING_KERNEL weights for 2D linearly interpolated voting.
%
% The function returns voting kernel for the given window size. The kernel
% takes care of exact pixel location. The sum of the kernel should match
% the area of the window.
%
%   y = (x + 0.5) / window_size(i) - 0.5
%
  assert(numel(window)==2);
  y_range = ceil(-window(1) * 0.5 - 0.5):floor(window(1) * 1.5 - 0.5);
  x_range = ceil(-window(2) * 0.5 - 0.5):floor(window(2) * 1.5 - 0.5);
  kern_y = 1 - abs((y_range + 0.5) / window(1) - 0.5);
  kern_x = 1 - abs((x_range + 0.5) / window(2) - 0.5);
  kern = kern_y(:)*kern_x(:)';
end

function kern = block_kernel(window)
%BLOCK_KERNEL weights for neighboring block summation.
  assert(numel(window)==2);
  kern = zeros(window + 1);
  kern([1,end],[1,end]) = 1;
end