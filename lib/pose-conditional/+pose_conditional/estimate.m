function samples = estimate(model, samples, varargin)
%ESTIMATE Apply a pose estimator.
%
%    model: trained pose estimator, a scalar struct.
%    samples: input image, struct array with 'im' and 'context' fields.
%
  scale = 240; % 240 pixels each side.
  nms_threshold = 0.3;
  gt_output = false;
  gt_threshold = 0.3;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Scale', scale = varargin{i+1};
      case 'NMSThreshold', nms_threshold = varargin{i+1};
      case 'GTOutput', gt_output = varargin{i+1};
      case 'GTThreshold', gt_threshold = varargin{i+1};
    end
  end
  
  [samples.poses] = deal([]);
  if gt_output
    [samples.gt_poses] = deal([]);
  end
  for i = 1:numel(samples)
    if numel(samples) > 1
      logger('%s %d / %d', mfilename, i, numel(samples));
    end
    boxes = process(model, samples(i), scale);
    samples(i).poses = nms(boxes, nms_threshold);
    if gt_output
      samples(i).gt_poses = get_gtbox(samples(i), boxes, gt_threshold);
    end
  end
end

function box = process(model, sample, scale)
%PROCESS
  detector_threshold = model.thresh;
  normalized_sample = get_normalized_image_and_context(sample, scale);
  box = detect_fast(normalized_sample, model, detector_threshold);
  box(:, 1:end-2) = box(:, 1:end-2) / normalized_sample.scale;
end

function normalized_sample = get_normalized_image_and_context(sample, scale)
%GET_NORMALIZED_IMAGE_AND_CONTEXT Get image and context from the sample struct.
  im = imread_or_decode(sample.image, 'jpg');
  % Treat scale as a maximum image width/height.
  if all(scale > 1.0)
    if isscalar(scale), scale = [scale, scale]; end
    scale = min(1.0, max(scale ./ [size(im, 1), size(im, 2)]));
  end
  normalized_sample.image = imresize(im, scale);
  if isfield(sample, 'context')
    context = imread_or_decode(sample.context, 'png');
    assert(size(im, 1) == size(context, 1) && size(im, 2) == size(context, 2));
    normalized_sample.context = imresize(context, scale, 'nearest');
  end
  normalized_sample.scale = scale;
end

function box = get_gtbox(sample, boxes, gt_threshold)
%GET_GTBOX
  x = sample.point(:,1);
  y = sample.point(:,2);
  gtbox = [min(x) min(y) max(x) max(y)];
  box = bestoverlap(boxes, gtbox, gt_threshold);
end
