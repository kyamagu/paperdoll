function test_pose_conditional
%TEST_POSE_CONDITIONAL
  if ~exist('tmp/test_pose_conditional-samples.mat', 'file')
    samples = load_pose_dataset();
    samples = shrink_samples(samples, 0.35);
    save tmp/test_pose_conditional-samples.mat samples;
  else
    load tmp/test_pose_conditional-samples.mat samples;
  end
  model = pose_conditional.train(samples, ...
                                 'CacheDir', 'tmp/test_pose_conditional');
  save tmp/test_pose_conditional.mat model;
  load tmp/test_pose_conditional.mat model;
  if ~exist('tmp/test_pose_conditional-test-samples.mat', 'file')
    samples = load_test_dataset();
    %samples = shrink_samples(samples, 0.35);
    save tmp/test_pose_conditional-test-samples.mat samples;
  else
    load tmp/test_pose_conditional-test-samples.mat samples;
  end
  model.thresh = min(model.thresh, -1.5);
  samples = pose_conditional.estimate(model, samples, 'GTOutput', true);
  evaluation = pose.evaluate(samples);
  save tmp/test_pose_conditional-evaluation.mat evaluation;
end

function samples = load_pose_dataset()
%LOAD_POSE_DATASET
  % Positive samples.
  logger('Loading pose training data.');
  load data/fashionista_v0.2.mat truths test_index;
  truths(test_index) = [];
  %truths = truths(1:100);
  pose_annotations = [truths.pose];
  positives = struct('image', {truths.image}, ...
                     'context', cell(1, numel(truths)), ...
                     'context_labels', cell(1, numel(truths)), ...
                     'point', {pose_annotations.point});
  for i = 1:numel(truths)
    [...
      positives(i).context, ...
      positives(i).context_labels, ...
    ] = get_clothing_annotation(truths(i).annotation);
  end
  % Negative samples.
  logger('Loading pose negative data.');
  load data/INRIA_data.mat samples;
  %samples = samples(1:100);
  negatives = struct('image', {samples.im}, ...
                     'context', cell(1, numel(samples)), ...
                     'context_labels', repmat({'null'}, 1, numel(samples)), ...
                     'point', cell(1, numel(samples)));
  for i = 1:numel(negatives)
    negatives(i).context = render_null_context(negatives(i).image);
  end
  samples = [positives, negatives];
end

function [new_annotation, labels] = get_clothing_annotation(annotation)
%CONVERT_ANNOTATION Convert annotation format for training.
  superpixel_index = imdecode(annotation.superpixel_map);
  labeling = annotation.superpixel_labels(superpixel_index);
  new_annotation = imencode(uint8(labeling), 'png');
  labels = annotation.labels;
end

function annotation = render_null_context(encoded_image)
%RENDER_NULL_CONTEXT
  image_size = size(imdecode(encoded_image, 'jpg'));
  annotation = ones(image_size(1), image_size(2), 'uint8');
  annotation = imencode(annotation, 'png');
end

function samples = shrink_samples(samples, scale)
%SHRINK_SAMPLES Resize images for training.
  logger('Shrinking images.');
  for i = 1:numel(samples)
    image = imdecode(samples(i).image, 'jpg');
    context = imdecode(samples(i).context, 'png');
    image = imresize(image, scale);
    context = imresize(context, scale, 'nearest');
    image_size = size(image);
    samples(i).image = imencode(image, 'jpg');
    samples(i).context = imencode(context, 'png');
    if ~isempty(samples(i).point)
      point = max(round(samples(i).point * scale), 1);
      point(:,1) = min(point(:,1), image_size(2));
      point(:,2) = min(point(:,2), image_size(1));
      samples(i).point = point;
    end
  end
end

function positives = load_test_dataset()
%LOAD_TEST_DATASET
  logger('Loading pose testing data.');
  load data/fashionista_v0.2.mat truths test_index;
  truths(~test_index) = [];
  %truths = truths(1:100);
  pose_annotations = [truths.pose];
  positives = struct('image', {truths.image}, ...
                     'context', cell(1, numel(truths)), ...
                     'context_labels', cell(1, numel(truths)), ...
                     'point', {pose_annotations.point});
  for i = 1:numel(truths)
    [...
      positives(i).context, ...
      positives(i).context_labels, ...
    ] = get_clothing_annotation(truths(i).annotation);
  end
end
