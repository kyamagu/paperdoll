function features = get_dense_features( config, samples )
%GET_DENSE_FEATURES Convert feature struct to dense feature map.

  features = cell(size(samples));
  for i = 1:numel(samples)
    feature = cellfun(@(name)im2double(samples(i).(name)), ...
                      config.input, ...
                      'UniformOutput', false);
    features{i} = cat(3, feature{:});
  end
  features = cat(4, features{:});

end