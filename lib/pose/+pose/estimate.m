function [boxes] = estimate(model, samples, varargin)
%ESTIMATE Apply a pose estimator.
%
%    model: trained pose estimator, a scalar struct.
%    samples: image, struct array with 'im' field, or cell string of image paths.
%

  scale = 0.5;
  nms_threshold = 0.3;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Scale', scale = varargin{i+1};
      case 'NMSThreshold', nms_threshold = varargin{i+1};
    end
  end
  
  if isnumeric(samples), samples = {samples}; end
  if isstruct(samples), samples = {samples.im}; end
  boxes = cell(size(samples));
  for i = 1:numel(samples)
    boxes{i} = process(model, samples{i}, scale, nms_threshold);
  end
  if isscalar(boxes), boxes = boxes{1}; end

end

function boxes = process(model, sample, scale, nms_threshold)
  detector_threshold = model.thresh;
  im = sample;
  if ischar(im)
      im = imread(im);
  end
  % Treat scale as a maximum image width/height.
  if scale > 1.0
    scale = min(1.0, scale / max(size(im, 1), size(im, 2)));
  end
  im = imresize(im, scale);
  box = detect_fast(im, model, detector_threshold);
  box(:, 1:end-2) = box(:, 1:end-2) / scale;
  boxes = nms(box, nms_threshold);
end
