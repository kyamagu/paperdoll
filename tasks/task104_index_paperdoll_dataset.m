function task104_index_paperdoll_dataset
%TASK104_INDEX_PAPERDOLL_DATASET Merge and index precomputed samples.
  input_dir = 'tmp/task103';
  pipeline_file = 'tmp/task101_offline_pipeline.mat';
  descriptor_file = 'tmp/task104_paperdoll_descriptors.mat';
  exemplars_db_file = 'data/paperdoll_exemplars.bdb';
  
  tags = load_clothing_labels(pipeline_file);
  files = dir(fullfile(input_dir, '*.mat'));
  sample_ids =  cell(size(files));
  descriptors = cell(size(files));
  taggings =    cell(size(files));
  for i = 1:numel(files)
    input_file = fullfile(input_dir, files(i).name);
    [sample_ids{i}, descriptors{i}, taggings{i}] = ...
        process_samples(input_file, exemplars_db_file, tags);
  end
  sample_ids = cat(1, sample_ids{:});
  descriptors = cat(1, descriptors{:});
  taggings = cat(1, taggings{:});
  assert(size(sample_ids, 1) == size(taggings, 1));
  assert(size(sample_ids, 1) == size(descriptors, 1));
  logger('Saving %d descriptors for retrieval.', numel(sample_ids));
  save(descriptor_file, 'sample_ids', ...
                        'descriptors', ...
                        'taggings', ...
                        'tags');
end

function labels = load_clothing_labels(pipeline_file)
%LOAD_CLOTHING_LABELS
  load(pipeline_file, 'config');
  localizer_index = cellfun(@(x)strcmp(x.name, 'clothing_localizer'), ...
                            config);
  labels = setdiff(config{localizer_index}.labels, ...
                   {'null', 'skin', 'hair'});
end

function [sample_ids, descriptors, taggings] = ...
    process_samples(input_file, exemplars_db_file, labels)
%PROCESS_SAMPLES
  logger('Importing %s', input_file);
  db_id = bdb.open(exemplars_db_file);
  try
    load(input_file, 'values');
    sample_ids = cat(1, values.id);
    descriptors = cat(1, values.style_descriptor2);
    taggings = false(numel(values), numel(labels));
    for i = 1:numel(values)
      taggings(i, :) = cellfun(@(x)any(strcmp(x, values(i).tagging)), ...
                               labels);
      value = rmfield(values(i), {'style_descriptor2', 'tagging'});
      % Comment out following for debugging.
      value = rmfield(value, ...
                      {'id', 'pose', 'normal_image', 'normal_pose'});
      bdb.put(db_id, values(i).id, value);
    end
    taggings = sparse(taggings);
  catch e
    disp(e.getReport);
  end
  bdb.close(db_id);
end
