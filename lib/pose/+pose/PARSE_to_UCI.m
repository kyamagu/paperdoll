function [samples, pa] = PARSE_to_UCI(samples)
%PARSE_to_UCI Convert PARSE data format to UCI data format
%
% See also PARSE_from_UCI

  % -------------------
  % create ground truth keypoints for model training
  % We augment the original 14 joint positions with midpoints of joints, 
  % defining a total of 26 keypoints
  I = [1  2  3  4   4   5  6   6   7  8   8   9   9   10 11  11  12 13  13  14 ...
             15 16  16  17 18  18  19 20  20  21  21  22 23  23  24 25  25  26];
  J = [14 13 9  9   8   8  8   7   7  9   3   9   3   3  3   2   2  2   1   1 ...
             10 10  11  11 11  12  12 10  4   10  4   4  4   5   5  5   6   6];
  A = [1  1  1  1/2 1/2 1  1/2 1/2 1  2/3 1/3 1/3 2/3 1  1/2 1/2 1  1/2 1/2 1 ...
             1  1/2 1/2 1  1/2 1/2 1  2/3 1/3 1/3 2/3 1  1/2 1/2 1  1/2 1/2 1];
  Trans = full(sparse(I,J,A,26,14));

  for i = 1:numel(samples)
    samples(i).point = Trans * samples(i).point; % linear combination
  end
  
  % Parent links.
  pa = [0 1 2 3 4 5 6 3 8 9 10 11 12 13 2 15 16 17 18 15 20 21 22 23 24 25];

end
