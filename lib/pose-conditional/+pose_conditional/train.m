function model = train(samples, varargin)
%TRAIN Train a new pose estimator.
%
% ## Input
%  * __samples__ Struct array of image data and annotation.
%    * __image__ File path to a JPEG image, or JPEG-encoded image binary data.
%    * __context__ File path to a PNG image, or PNG-encoded image binary data.
%    * __point__ 14-by-2 row vectors (x,y) of pose keypoints for positive
%                samples, or empty for negative samples. The order of point is
%                the following.
%
%     {...
%         'right_ankle',...
%         'right_knee',...
%         'right_hip',...
%         'left_hip',...
%         'left_knee',...
%         'left_ankle',...
%         'right_hand',...
%         'right_elbow',...
%         'right_shoulder',...
%         'left_shoulder',...
%         'left_elbow',...
%         'left_hand',...
%         'neck',...
%         'head'...
%     }
%
% ## Output
%  * __model__ Struct of trained pose estimator model.
%
% ## Options
%  * __'CacheDir'__ Where cache files are stored. Default TEMPDIR(). When the
%                   default value is used, the directory will be removed after
%                   finish.
%

  cache_directory = tempname('tmp');
  remove_cache_directory = true;
  disable_context = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'CacheDir'
        cache_directory = varargin{i+1};
      case 'RemoveCacheDir'
        remove_cache_directory = varargin{i+1};
      case 'DisableContext'
        disable_context = varargin{i+1};
    end
  end
  assert(isfield(samples, 'image'));
  assert(isfield(samples, 'point'));
  if disable_context && isfield(samples, 'context')
    samples = rmfield(samples, 'context');
  end

  cachedir(cache_directory);
  try
    samples = write_image_files(fullfile(cache_directory, 'images'), samples);
    positive_index = find_positive_samples(samples);
    model = trainmodel('_', ...
                       pose.PARSE_to_UCI(samples(positive_index)), ...
                       pose.PARSE_to_UCI(samples(positive_index)), ...
                       ...samples(~positive_index), ...
                       varargin{:});
    if remove_cache_directory, rmdir(cache_directory, 's'); end
  catch e
    if remove_cache_directory, rmdir(cache_directory, 's'); end
    rethrow(e);
  end

end

function samples = write_image_files(root_dir, samples)
%WRITE_IMAGE_FILES

  if ~exist(root_dir, 'dir'), mkdir(root_dir); end
  for i = 1:numel(samples)
    if isvector(samples(i).image) && isa(samples(i).image, 'uint8')
      filename = fullfile(root_dir, sprintf('%04d.jpg', i));
      write_binary_to_file(samples(i).image, filename);
      samples(i).image = filename;
    end
    if isfield(samples, 'context') && ...
       isvector(samples(i).context) && ...
       isa(samples(i).context, 'uint8')
      filename = fullfile(root_dir, sprintf('%04d.png', i));
      write_binary_to_file(samples(i).context, filename);
      samples(i).context = filename;
    end
  end

end

function positive_index = find_positive_samples(samples)
%FIND_POSITIVE_SAMPLES
  positive_index = ~cellfun(@isempty, {samples.point});
end
