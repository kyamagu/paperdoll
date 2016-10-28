function [keys, values] = load_from_matfiles(filepattern)
%LOAD_FROM_MATFILES Load data from split matfiles.
%
%    values = load_from_matfiles(filepattern)
%    [keys, values] = load_from_matfiles(filepattern)
% 
% The function loads data saved into split matfiles using
% save_into_matfiles(). The filepattern must include `*_of_N` pattern
% where N is the number of splits.
%
% Example
%
%    mydata = load_from_matfiles('tmp/mydata/*_of_10.mat');
%
% See also save_into_matfiles 

  files = dir(filepattern);
  if isempty(files)
    error('Missing input files: %s', filepattern);
  end
  assert(numel(files) == ...
         cellfun(@str2double,...
                 regexp(files(1).name, '\d+_of_(\d+)\.mat', 'tokens')));
  root_dir = fileparts(filepattern);
  keys = cell(size(files));
  values = cell(size(files));
  for i = 1:numel(files)
    filename = fullfile(root_dir, files(i).name);
    file_content = load(filename, 'keys', 'values');
    keys{i} = file_content.keys;
    values{i} = file_content.values;
  end
  dim_to_cat = (all(cellfun(@(x)size(x, 1), keys) == 1)) + 1;
  keys = cat(dim_to_cat, keys{:});
  dim_to_cat = (all(cellfun(@(x)size(x, 1), values) == 1)) + 1;
  values = cat(dim_to_cat, values{:});
  [keys, order] = sort(keys);
  values = values(order);
  if nargout < 2, keys = values; end
  
end

