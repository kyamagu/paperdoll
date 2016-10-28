function task103_precompute_paperdoll_dataset
%TASK103_PRECOMPUTE_PAPERDOLL_DATASET
  input_dir = 'tmp/task102';
  output_dir = 'tmp/task103';
  pipeline_file = 'tmp/task101_offline_pipeline.mat';
  image_db = 'data/paperdoll_photos/photos.bdb';
  
  info = sge_environment;
  if isnan(info.sge_task_id), info.sge_task_id = 1; end
  load(fullfile(input_dir, sprintf('%04d_of_1000.mat', info.sge_task_id)), ...
       'keys', 'values');
  values = load_images(image_db, values);
  config = load_pipeline(pipeline_file);
  logger('Estimating pose.');
  values = feature_calculator.apply(config(1), values);
  
  values = values(~cellfun(@isempty, {values.pose}));
  logger('Computing features.');
  values = feature_calculator.apply(config(2:end), values, ...
                                    'Precompute', true, ...
                                    'Rescue', true);
  keys = [values.id];
  if ~exist(output_dir, 'dir'), mkdir(output_dir); end
  save(fullfile(output_dir, sprintf('%04d_of_1000.mat', info.sge_task_id)), ...
       'keys', 'values');
end

function config = load_pipeline(filename)
%LOAD_PIPELINE Load trained calculators.
  load(filename, 'config');
  % Append field extractor.
  config = [...
    config, ...
    field_extractor.create(...
      'Output', {...
        'id', ...
        'normal_image', ...
        'pose', ...
        'normal_pose', ...
        'style_descriptor2', ...
        'tagging', ...
        'clothing_labels', ...
        ...'refined_labels', ... Uncomment for debugging.
        ...'refined_labeling' ... Uncomment for debugging.
        'segment_geometry', ...
        'segment_bow', ...
        'segment_localization', ...
        'exemplar_annotation', ...
        'exemplar_features' ...
        }...
    ) ...
    ];
end

function values = load_images(image_db, values)
%LOAD_IMAGES Load images.
  logger('Loading images from %s', image_db);
  db_id = bdb.open(image_db, 'Create', false, 'Rdonly');
  [values.clothing_labels] = deal([]);
  [values.image] = deal([]);
  for i = 1:numel(values)
    try
      values(i).clothing_labels = ['null', 'skin', 'hair', values(i).tagging];
      image_data = bdb.get(db_id, values(i).id);
      if isempty(image_data)
        error('Empty image at id=%d', values(i).id);
      end
      values(i).image = image_data;
    catch e
      logger(e.getReport);
    end
  end
  values = values(~cellfun(@isempty, {values.image}));
  bdb.close(db_id);
end
