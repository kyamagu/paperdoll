function samples = apply(config, samples, varargin)
%APPLY Apply softmask transferer to samples.
  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  PRECOMPUTE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
      case 'Precompute', PRECOMPUTE = varargin{i+1};
    end
  end

  % Only run precomputation.
  if PRECOMPUTE
    samples = softmask_transferer.precompute(config, samples, varargin{:});
    return;
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), ...
                                       [config.input, ...
                                        config.input_pose_map]);
    [softmask_transfer, labels] = process_sample(config, sample);
    if ENCODE
      softmask_transfer = encode_3d_array(softmask_transfer);
    end
    samples(i).(config.output) = softmask_transfer;
    samples(i).(config.output_labels) = labels;
  end
end

function [softmask_transfer, labels, segmentation] = process_sample(config, sample)
%PROCESS_SAMPLE
  [exemplars, labels] = load_exemplars(config, sample);
  [query_segmentation, query_geometry, query_bow] = ...
      compute_segment_feature(config, sample);
  num_segments = size(query_geometry, 1);
  transfered_localizations = zeros(num_segments, ...
                                   numel(labels), ...
                                   numel(exemplars));
  for i = 1:numel(exemplars)
    exemplar_geometry = exemplars(i).(config.output_segment_geometry);
    exemplar_bow = exemplars(i).(config.output_segment_bow);
    exemplar_localization = relabel_localization(...
        exemplars(i).(config.output_segment_localization), ...
        exemplars(i).(config.exemplar_labels), ...
        labels ...
        );
    candidate_indices = find_nearest_segments_by_geometry(config, ...
                                                          query_geometry, ...
                                                          exemplar_geometry);
    [matched_indices, matched_distances] = ...
        find_nearest_segment_by_appearance(query_bow, ...
                                           exemplar_bow, ...
                                           candidate_indices);
    transfered_localizations(:, :, i) = ...
        transfer_localization(matched_indices, ...
                              matched_distances, ...
                              double(exemplar_localization));
  end
  [softmask_transfer, labels] = ...
      compute_softmask_transfer(transfered_localizations, ...
                                query_segmentation, ...
                                labels);
  segmentation = query_segmentation;
end

function [exemplars, labels] = load_exemplars(config, sample)
%LOAD_EXEMPLARS Load exemplars from the database.
  persistent database_id;
  if isempty(database_id)
    database_id = bdb.open(config.database_file, 'Rdonly', true, ...
                                                 'Create', false);
  end
  exemplar_ids = sample.(config.input_exemplar_ids);
  exemplar_ids = exemplar_ids(1:min(config.num_exemplars, ...
                                    numel(exemplar_ids)));
  logger('Retrieving %d nearest neighbors.', numel(exemplar_ids));
  exemplars = cell(size(exemplar_ids));
  for i = 1:numel(exemplars)
    exemplars{i} = bdb.get(database_id, exemplar_ids(i));
  end
  exemplars = [exemplars{:}];
  labels = unique([exemplars.(config.exemplar_labels)]);
  reserved_labels = {'null', 'skin', 'hair'};
  labels = [reserved_labels, setdiff(labels, reserved_labels)];
end

function relabeled_localization = relabel_localization(localization, ...
                                                       source_labels, ...
                                                       target_labels)
%RELABEL_LOCALIZATION Reorder columns of the localization.
  relabeled_localization = zeros(size(localization, 1), numel(target_labels));
  for i = 1:numel(source_labels)
    index = strcmp(source_labels{i}, target_labels);
    assert(any(index));
    relabeled_localization(:, index) = localization(:, i);
  end
end

function segment_indices = find_nearest_segments_by_geometry(config, ...
                                                             query_segment_feature, ...
                                                             exemplar_segment_feature)
%FIND_NEAREST_SEGMENTS_BY_POSE Find closest K segments in terms of geometry.
  distances = pdist2(query_segment_feature, exemplar_segment_feature);
  [~, segment_indices] = sort(distances, 2, 'ascend');
  segment_indices = segment_indices(:, 1:config.num_matches);
end

function [indices, distances] = find_nearest_segment_by_appearance(query_bow, ...
                                                                   exemplar_bow, ...
                                                                   candidate_indices)
%FIND_NEAREST_SEGMENT_BY_APPEARANCE Find the most similar segment from the candidates.
  indices = zeros(size(query_bow, 1), 1);
  distances = zeros(size(query_bow, 1), 1);
  for i = 1:size(query_bow, 1)
    distance = pdist2(query_bow(i, :), ...
                      exemplar_bow(candidate_indices(i, :), :));
    [min_distance, min_index] = min(distance, [], 2);
    indices(i) = candidate_indices(i, min_index);
    distances(i) = min_distance;
  end
end

function [transfered_localization] = transfer_localization(matched_indices, ...
                                                           matched_distances, ...
                                                           exemplar_localization)
%TRANSFER_LOCALIZATION Compute weighted contribution from segments.
  transfered_localization = diag(sparse(1 ./ (1 + matched_distances(:)))) * ...
                            exemplar_localization(matched_indices, :);
end

function [softmask_transfer, labels] = compute_softmask_transfer(transfered_localizations, ...
                                                                 segmentation, ...
                                                                 labels)
%COMPUTE_SOFTMASK_TRANSFER Aggregate and compute the final transfered mask.
  transfered_localization = sum(transfered_localizations, 3);
  sum_transfered_localization = sum(transfered_localization, 2);
  % Add 'unknown' label if there is all-zero region.
  empty_index = sum_transfered_localization == 0;
  if any(empty_index)
    labels = [labels, 'unknown'];
    transfered_localization = [transfered_localization, double(empty_index)];
    sum_transfered_localization = sum(transfered_localization, 2);
  end
  % Normalize transfered localization.
  transfered_localization = diag(sparse(1 ./ (sum_transfered_localization))) * ...
                            transfered_localization;
  assert(~any(isnan(transfered_localization(:))));
  softmask_transfer = transfered_localization(segmentation(:), :);
  softmask_transfer = reshape(softmask_transfer, ...
                              [size(segmentation), size(softmask_transfer, 2)]);
end
