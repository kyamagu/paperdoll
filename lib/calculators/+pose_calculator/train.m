function [config, samples] = train(config, samples, varargin)
%TRAIN Train a calculator configuration.

  assert(isfield(samples, config.input));
  if ~isempty(config.model)
    logger('Computing %s', config.output);
    samples = pose_calculator.apply(config, samples, varargin{:});
    return;
  end
  assert(isfield(samples, config.input_annotation));

  % Resize images.
  training_samples = shrink_samples(config, samples);

  % Train a model.
  config.model = pose.train(training_samples, ...
                            'CacheDir', config.cache_dir);

  if nargout > 1
    logger('Computing %s', config.output);
    calculator = str2func([config.name,'.apply']);
    samples = calculator(config, samples, varargin{:});
  end

end

function samples = shrink_samples(config, truths)
%SHRINK_SAMPLES Resize images for training.
  samples = struct('im', {truths.(config.input)}, ...
                   'point', {truths.(config.input_annotation)});
  for i = 1:numel(samples)
    if ~isempty(samples(i).point)
      im = imdecode(samples(i).im, 'jpg');
      im = imresize(im, config.scale);
      image_size = size(im);
      point = max(round(samples(i).point * config.scale), 1);
      point(:,1) = min(point(:,1), image_size(2));
      point(:,2) = min(point(:,2), image_size(1));
      samples(i).im = imencode(im);
      samples(i).point = point;
    end
  end
end