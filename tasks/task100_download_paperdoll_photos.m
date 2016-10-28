function task100_download_paperdoll_photos
%TASK100_DOWNLOAD_PAPERDOLL_PHOTOS
%
% Download photos for the PaperDoll dataset. Be mindful to copyrighted
% images.
%
  paperdoll_file = 'data/paperdoll_dataset.mat';
  image_db = 'data/paperdoll_photos';
  num_splits = 4;
  
  if ~exist(image_db, 'dir')
    mkdir(image_db);
  end
  logger('Loading %s', paperdoll_file);
  load(paperdoll_file, 'samples');
  samples = split_array(samples, num_splits);
  
  matlabpool('open', num_splits);
  parfor i = 1:num_splits
    download_photos(samples{i}, image_db);
  end
  matlabpool('close');

  logger('Finished');
end

function output = split_array(input, num_splits)
%SPLIT_ARRAY Split array into groups.
  output = cell(1, num_splits);
  index = ceil((1:numel(input))'/numel(input) * num_splits);
  for i = 1:num_splits
    output{i} = input(index == i);
  end
end

function download_photos(samples, image_db)
%LOAD_IMAGES Load images.
  env_id = bdb.env_open(image_db);
  db_id = bdb.open('photos.bdb');
  for i = 1:numel(samples)
    try
      sample = samples(i);
      if ~bdb.exist(db_id, sample.id)
        logger('Downloading %s', sample.url);
        image_data = download_image_url(sample.url);
        bdb.put(db_id, sample.id, image_data);
      end
    catch e
      logger(e.getReport);
    end
  end
  bdb.close(db_id);
  bdb.env_close(env_id);
end

function output = download_image_url(url)
%DOWNLOAD_IMAGE_URL Fetch an image from URL.
  filename = tempname;
  try
    urlwrite(url, filename);
    fid = fopen(filename, 'r');
    output = fread(fid, inf, 'uint8=>uint8');
    fclose(fid);
    delete(filename);
  catch e
    if exist(filename, 'file')
      delete(filename);
    end
    rethrow(e);
  end
end
