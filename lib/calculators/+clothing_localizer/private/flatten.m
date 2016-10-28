function features = flatten(config, sample)
%FLATTEN_FEATURES Flatten sample struct into row vectors of dense features.

  features = cellfun(@(name)im2double(sample.(name)), ...
                     config.input, ...
                     'UniformOutput', false);
  features = cat(3, features{:});
  features = reshape(features,...
                     [size(features,1)*size(features,2), size(features,3)]);

end

