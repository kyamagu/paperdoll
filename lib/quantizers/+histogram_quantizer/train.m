function [model, projections] = train(samples, varargin)
%TRAIN Train a histogram quantizer.

  % Use K bins.
  K = 10;
  mark_delete = false(size(varargin));
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'K'
        K = varargin{i+1};
        mark_delete(i:i+1) = true;
    end
  end
  varargin(mark_delete) = [];

  % Check if the input is row vectors.
  assert(isnumeric(samples));
  if ndims(samples) > 2
    siz = size(samples);
    samples = reshape(samples, [siz(1)*siz(2), prod(siz(3:end))]);
  end
  
  model.name = 'histogram_quantizer';
  model.ticks = zeros(K + 1, size(samples, 2));
  for i = 1:size(samples, 2)
    model.ticks(:, i) = linspace(min(samples(:, i)), ...
                                 max(samples(:, i)), ...
                                 K + 1)';
  end
  model.stepsize = model.ticks(2, :) - model.ticks(1, :);
  if nargout > 1
    projections = histogram_quantizer.project(model, samples);
  end

end

