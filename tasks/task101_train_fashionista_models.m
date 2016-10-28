function task101_train_fashionista_models
%TASK101_TRAIN_FASHOINISTA_MODELS

  % Train a pose calculator.
  if exist('tmp/task101_pose_calculator.mat', 'file')
    load tmp/task101_pose_calculator.mat config;
  else
    samples = load_pose_dataset();
    config = pose_calculator.create();
    config = pose_calculator.train(config, samples);
    save tmp/task101_pose_calculator.mat config;
  end

  % Train a style descriptor, a global model, and a softmask feature.
  [samples, labels] = load_fashionista_dataset();
  samples = convert_fashionista_annotation(samples);
  config = [{config}, create_pipeline(labels)];
  config(2:end) = feature_calculator.train(config(2:end), samples);
  save tmp/task101_feature_calculators.mat config;
  
  % Prepare a pipeline for offline precomputing.
  config = [config, ...
    gradient_calculator.create, ...
    clothing_refiner2.create(...
      'InputLabels', 'clothing_labels', ...
      'InputLocalization', 'clothing_localization', ...
      'ClothingRefinerAddUnknown', true ...
      ), ...
    exemplar_localizer2.create ...
    ];
  save tmp/task101_offline_pipeline.mat config;
end

function samples = load_pose_dataset()
%LOAD_POSE_DATASET
  logger('Loading pose training data.');
  % Positive samples.
  load data/fashionista_v0.2.mat truths test_index;
  truths(test_index) = [];
  pose_annotations = [truths.pose];
  positives = struct('image', {truths.image}, ...
                     'point', {pose_annotations.point});
  % Negative samples.
  load data/INRIA_data.mat samples;
  negatives = struct('image', {samples.im}, ...
                     'point', cell(1, numel(samples)));
  samples = [positives, negatives];
end

function [truths, labels] = load_fashionista_dataset()
%LOAD_FASHIONISTA_DATASET
  logger('Loading Fashionista training data.');
  load data/fashionista_v0.2.mat truths test_index;
  truths(test_index) = [];
  labels = truths(1).annotation.labels;
end

function samples = convert_fashionista_annotation(samples)
%CONVERT_ANNOTATIONS Convert data format for training.
  logger('Converting fashionista data.');
  % Retrieve annotations.
  for i = 1:numel(samples)
    [...
      samples(i).clothing_annotation, ...
      samples(i).clothing_annotation_labels, ...
      samples(i).clothing_tags, ...
    ] = get_clothing_annotation(samples(i).annotation);
    samples(i).skinhair_annotation = get_skinhair_annotation(...
        samples(i).annotation);
    samples(i).pose_annotation = samples(i).pose;
  end
  samples = rmfield(samples, 'annotation');

  % Warp annotations.
  logger('Warping fashionista annotations.');
  config = feature_calculator.create(...
    'normal_pose_calculator', {...
      'InputImage',  'clothing_annotation', ...
      'InputPose',   'pose_annotation', ...
      'OutputImage', 'normal_clothing_annotation', ...
      'OutputPose',  'normal_pose_annotation' ...
    },...
    'normal_pose_calculator', {...
      'InputImage',  'skinhair_annotation', ...
      'InputPose',   'pose_annotation', ...
      'OutputImage', 'normal_skinhair_annotation' ...
    }...
    );
  samples = feature_calculator.apply(config, ...
                                     samples, ...
                                     'NormalPoseImageFormat', 'png', ...
                                     'NormalPoseInterpolation', 'Nearest');
  samples = rmfield(samples, 'skinhair_annotation');
  samples = rmfield(samples, 'normal_pose');
  samples = rmfield(samples, 'normal_transform');
end

function config = create_pipeline(labels)
%CREATE_PIPELINE Create a pipeline to train.
  config = [...
    style_descriptor2.create_default_pipeline(), ...
    clothing_localizer.create(...
      'Labels', labels, ...
      'InputAnnotation', 'normal_clothing_annotation' ...
      ), ...
    softmask_transferer.create() ...
    ];
end

function [new_annotation, labels, tags] = get_clothing_annotation(annotation)
%CONVERT_ANNOTATION Convert annotation format for training.
  superpixel_index = imdecode(annotation.superpixel_map);
  labeling = annotation.superpixel_labels(superpixel_index);
  new_annotation = imencode(uint8(labeling), 'png');
  labels = annotation.labels;
  tags = setdiff(labels(unique(labeling)), {'skin', 'hair', 'null'});
end

function new_annotation = get_skinhair_annotation(annotation)
%CONVERT_ANNOTATION Convert annotation format for internal features.
  % Get {'null', 'skin', 'hair', 'any'} annotation.
  label_mapping = 4*ones(size(annotation.labels));
  label_mapping(strcmp(annotation.labels, 'null')) = 1;
  label_mapping(strcmp(annotation.labels, 'skin')) = 2;
  label_mapping(strcmp(annotation.labels, 'hair')) = 3;
  superpixel_index = imdecode(annotation.superpixel_map);
  labeling = annotation.superpixel_labels(superpixel_index);
  new_annotation = label_mapping(labeling);
  new_annotation = imencode(uint8(new_annotation), 'png');
end
