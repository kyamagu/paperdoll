function paperdoll_worker2
%PAPERDOLL_WORKER Worker process for the Paper Doll Web.
  iptgetpref;
  cd(fileparts(fileparts(mfilename('fullpath'))));
  startup;
  %options.server = 'http://example.com/';  % Replace me with the real hosting service.
  options.parser_file = fullfile('data', 'paperdoll_pipeline.mat');
  options.database_file = fullfile('data', 'paperdoll_exemplars_debug.bdb');  % This file is a special database with images.
  options.worker_id = getenv('WORKER_ID');
  options.session_id = [];
  options.work_directory = '';
  [options, server_socket] = createTCPServerSocket(options);

  options = load_parser(options);
  json.startup;

  while true
    options = fetch_pending_job(options, server_socket);
    if ~isempty(options.work_directory)
      logger('Processing %s.', options.work_directory);
      try
        process_input(options);
      catch exception
        logger(exception.getReport());
        update_status(options, 'error', exception.getReport());
      end
    end
  end
end

function options = load_parser(options)
%LOAD_PARSER
  logger('Loading a parser.');
  load(options.parser_file, 'config');
  config{1}.scale = 200;
  config{1}.model.thresh = -2;
  config{13}.database_file = options.database_file;
  config{15}.database_file = options.database_file;
  config(end) = []; % Remove field cleaner.
  options.parser = config;
end

function [options, server_socket] = createTCPServerSocket(options)
%CREATETCPSERVERSOCKET
  server_socket = java.net.ServerSocket(0);
  options.worker_hostname = getenv('HOSTNAME');
  options.worker_port = server_socket.getLocalPort();
  logger('TCP Socket: %s:%d', options.worker_hostname, ...
                              options.worker_port);
end

function options = fetch_pending_job(options, server_socket)
%FETCH_PENDING_JOB
  notify_worker_status(options, 'available');
  request = org.apache.commons.io.IOUtils.toString(...
      server_socket.accept().getInputStream(), 'utf-8');
  logger(char(request));
  session = json.load(char(request));
  options.work_directory = [];
  if isstruct(session) && isfield(session, 'work_dir')
    options.work_directory = session.work_dir;
    options.session_id = session.id;
  end
end

function notify_worker_status(options, status)
%NOTIFY_WORKER_STATUS
  try
    [params, header] = http_paramsToString({...
        'worker[status]', status, ...
        'worker[hostname]', options.worker_hostname, ...
        'worker[port]', num2str(options.worker_port)...
        }, 1);
    url = [options.server, 'workers/', num2str(options.worker_id)];
    response = urlread2(url, 'PUT', params, header);
    logger(response);
  catch exception
    logger(exception.getReport());
  end
end

function update_status(options, status, message)
%UPDATE_STATUS
  try
    [params, header] = http_paramsToString({'status', status, ...
                                            'message', message}, 1);
    url = [options.server, 'sessions/', num2str(options.session_id)];
    response = urlread2(url, 'PUT', params, header);
  catch exception
    logger(exception.getReport());
  end
end

function process_input(options)
%PROCESS_INPUT Process a give directory.
  % Load an input.
  input_file = fullfile(options.work_directory, 'image.jpg');
  system(sprintf('touch %s', options.work_directory)); % Sync NFS.
  if exist(input_file, 'file') ~= 2
    update_status(options, 'error', sprintf('Input %s not found', input_file));
    return;
  else
    update_status(options, 'started', 'Estimating pose.');
  end
  sample = struct('image', read_binary_from_file(input_file));

  % Apply a pose estimator.
  logger('Applying a pose estimator.');
  sample = feature_calculator.apply(options.parser(1), sample);
  if isempty(sample)
    update_status(options, 'error', 'Failed to estimate pose.');
    return;
  else
    json.write(pose.PARSE_from_UCI(pose.box2point(sample.pose)), ...
               fullfile(options.work_directory, 'pose.json'));
    update_status(options, 'pose-estimated', 'Retrieving similar styles.');
  end

  % Retrieve nearest neighbors.
  logger('Retrieving nearest neighbors.');
  sample = feature_calculator.apply(options.parser(2:11), sample);
  export_retrieved_images(options, sample);
  update_status(options, 'retrieved', 'Computing a global parse.');

  % Parse an image.
  logger('Parsing an image.');
  sample = feature_calculator.apply(options.parser(12), sample);
  options.colors = [];
  options.labels = {};
  options = export_parse_result(options, ...
                                sample, ...
                                'clothing_localization', ...
                                'knn_predicted_labels', ...
                                'global');
  update_status(options, 'global-parsed', 'Computing a transferred parse.');
  sample = feature_calculator.apply(options.parser(13), sample);
  options = export_parse_result(options, ...
                                sample, ...
                                'softmask_transfer', ...
                                'softmask_labels', ...
                                'transferred');
  update_status(options, 'transferred-parsed', 'Computing a nearest neighbor parse.');
  sample = feature_calculator.apply(options.parser(14:15), sample);
  options = export_parse_result(options, ...
                                sample, ...
                                'exemplar_localization', ...
                                'exemplar_labels', ...
                                'nearest');
  update_status(options, 'nearest-parsed', 'Combining parses.');
  sample = feature_calculator.apply(options.parser(16), sample);
  options = export_parse_result(options, ...
                                sample, ...
                                'combined_localization', ...
                                'combined_labels', ...
                                'combined');
  update_status(options, 'combined-parsed', 'Applying iterative smoothing.');
  sample = feature_calculator.apply(options.parser(17:end), sample);
  export_parse_result(options, sample, 'final_labeling', 'refined_labels', 'parse');
  logger('Finished.');
  update_status(options, 'finished', 'Successfully parsed an input image.');
end

function export_retrieved_images(options, sample)
%EXPORT_RETRIEVED_IMAGES
  output_metadata_file = fullfile(options.work_directory, 'retrieval.json');
  output_files = arrayfun(@(i)fullfile(options.work_directory, ...
                                       sprintf('similar%d.jpg', i)), ...
                          1:6, ...
                          'UniformOutput', false);
  persistent database;
  if isempty(database)
    database = bdb.open(options.database_file, 'Rdonly', 'Create', false);
  end
  metadata = struct('candidate_labels', {sample.knn_predicted_labels}, ...
                    'retrieved_labels', {cell(size(output_files))});
  for i = 1:numel(output_files)
    nn_sample = bdb.get(database, sample.knn_retrieved_ids(i));
    assert(~isempty(nn_sample));
    write_binary_to_file(nn_sample.normal_image, output_files{i});
    metadata.retrieved_labels{i} = nn_sample.clothing_labels;
  end
  json.write(metadata, output_metadata_file);
end

function options = export_parse_result(options, sample, labeling_field, labels_field, output_name)
%EXPORT_PARSE_RESULT
  output_image_file = fullfile(options.work_directory, [output_name, '.png']);
  output_metadata_file = fullfile(options.work_directory, [output_name, '.json']);
  [index_map, options] = visualize_parse(sample.(labeling_field), ...
                                         sample.(labels_field), ...
                                         options);
  unique_index = unique(index_map(:));
  imwrite(double(index_map), options.colors, output_image_file);
  json.write(struct('labels', {options.labels(unique_index)}, ...
                    'colors', im2uint8(options.colors(unique_index, :))), ...
             output_metadata_file);
end

function [index_map, options] = visualize_parse(labeling, labels, options)
%VISUALIZE_PARSE Apply colormap to the index map and label set.
  if size(labeling, 3) > 1
    [~, labeling] = max(labeling, [], 3);
  end
  index_map = imread_or_decode(labeling);
  [unique_index, ~, index_map(:)] = unique(index_map(:));
  labels = labels(unique_index);

  % Merge and reorder labels.
  merged_labels = union(options.labels, labels);
  options.labels = [{'null', 'skin', 'hair'}, ...
                    setdiff(merged_labels(:)', {'null', 'skin', 'hair'})];
  mapping = cellfun(@(label)find(strcmp(label, options.labels), 1), labels);
  index_map = mapping(index_map);
  options.colors = [1,1,1;1,.75,.75;.2,.1,.1;hsv(numel(options.labels) - 3)];
end
