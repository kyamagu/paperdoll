function output = expand_feature(input, order, varargin)
%EXPAND_FEATURE Expand row vectors by raising the specified order.

  INDEPENDENT = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Independent', INDEPENDENT = varargin{i+1};
    end
  end
  
  orders = cell(1, order);
  for i = 1:order
    if INDEPENDENT
      index_comb = repmat((1:size(input, 2))', 1, i);
    else
      index_comb = make_combination(1:size(input, 2), i);
    end
    combinations = cell(1, size(index_comb, 1));
    for j = 1:size(index_comb, 1)
      combinations{j} = prod(input(:, index_comb(j,:)), 2);
    end
    orders{i} = [combinations{:}];
  end
  output = [ones(size(input, 1), 1), orders{:}]; % Append bias also.

end

function vcomb = make_combination(v, order)
%MAKE_COMBINATION Make unique combination of input to the specified order.
%
%    VCOMB = make_combination(V, ORDER)
%
% V is a vector of monotonically increasing, unique vector.

  assert(isvector(v));
  assert(isscalar(order));
  vcomb = unique(v(:));
  for i = 2:order
    vcomb = [kron(vcomb, ones(numel(v), 1)), repmat(v(:), size(vcomb, 1), 1)];
    vcomb(vcomb(:, end-1) > vcomb(:, end), :) = [];
  end

end