function task102_split_paperdoll_dataset
%TASK102_SPLIT_PAPERDOLL_DATASET
  output_dir = 'tmp/task102';
  load('data/paperdoll_dataset.mat', 'samples', 'labels');
  for i = 1:numel(samples)
    samples(i).tagging = labels(samples(i).tagging);
  end
  logger('Saving samples into mat files');
  if ~exist(output_dir, 'dir'), mkdir(output_dir); end
  save_into_matfiles(fullfile(output_dir, '*_of_1000.mat'), ...
                     [samples.id], ...
                     samples);
end