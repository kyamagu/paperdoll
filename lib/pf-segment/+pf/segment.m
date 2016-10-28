function [segmentation, num_segments] = segment(input_image, sigma, k, min_size)
%SEGMENT Image segmentation based on Pedro Felzenszwalb 2004
% 
%    [segmentation, num_segments] = pf.segment(input_image, sigma, k, min_size);
%
% Input:
%   input_image: uint8 type H-by-W-by-3 RGB array
%         sigma: scalar param used to smooth the input image before segmenting it
%             k: scalar param for the threshold function
%      min_size: param for minimum component size enforced by post-processing
% Output:
%  segmentation: double H-by-W-by-3 index array
%  num_segments: number of segments in double scalar
