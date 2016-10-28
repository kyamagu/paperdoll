function save_into_matfiles(filepattern, keys, values)
%SAVE_INTO_MATFILES Split value array or key-value array into files.
%
%    save_into_matfiles(filepattern, values)
%    save_into_matfiles(filepattern, keys, values)
%
% The function split a value array or a key-value pairs and saves into
% multiple MAT files. The first argument is a pattern of mat file names to
% save into. The keys and values must be a vector of any type. If they are
% not a vector, the function silently tries to flatten and save them.
%
% The filepattern must include `*_of_N` pattern where N is the number of
% split. `*` is substituted with split index.
%
% Example
%
%    mydata = num2cell(1:100);
%    save_into_matfiles('tmp/mydata/*_of_10.mat', mydata);
%
% See also load_from_matfiles

  if nargin < 3
    values = keys;
    keys = reshape(1:numel(keys), size(values));
  end
  assert(numel(keys) == numel(values), ...
         'Unmatched number of keys and values.');
  assert(~isempty(keys), 'Empty input.');
  if ~isvector(keys), keys = keys(:); end
  if ~isvector(values), values = values(:); end

  [root_dir, filepattern, fileext] = fileparts(filepattern);
  assert(strcmp(fileext, '.mat'));
  if ~exist(root_dir, 'dir'), mkdir(root_dir); end
  filepattern = [filepattern, fileext];
  num_splits = str2double(regexp(filepattern, ...
                                 '_of_(\d+)\.mat', 'tokens', 'once'));
  filepattern = strrep(filepattern, '*', ...
                       ['%0',num2str(floor(log10(num_splits))+1),'d']);
  index = ceil((1:numel(values))'/numel(values) * num_splits);
  for i = 1:num_splits
    file_content.keys = keys(index == i);
    file_content.values = values(index == i);
    filename = sprintf(fullfile(root_dir, filepattern), i);
    save(filename, '-struct', 'file_content');
  end

end

