function samples = apply(config, samples, varargin)
%APPLY Apply clothing localizer to input.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ENCODE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'Encode', ENCODE = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end

  % Compute map.
  [samples.(config.output)] = deal([]);
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    [localization, labels] = combine_localizations(config, sample);
    samples(i).(config.output) = localization;
    samples(i).(config.output_labels) = labels;
    if ENCODE
      samples(i) = feature_calculator.encode(samples(i), config.output);
    end
  end

end

function [localization, labels] = combine_localizations(config, sample)
  labels = {};
  for i = 1:numel(config.input_labels)
    labels = union(labels, sample.(config.input_labels{i}));
  end
  
  % Make probability map for the first component.
  component = log(sample.(config.input{1})) .* config.lambdas(1);
  input_labels = sample.(config.input_labels{1});
  image_size = size(sample.(config.input{1}));
  localization = -inf(image_size(1), image_size(2), numel(labels));
  for j = 1:numel(input_labels)
    index = find(strcmp(input_labels{j}, labels));
    if ~isempty(index)
      localization(:,:,index) = component(:,:,j);
    end
  end
  % Accumulate for the rest of the components.
  for i = 2:numel(config.input_labels)
    input_labels = sample.(config.input_labels{i});
    component = log(sample.(config.input{i})) .* config.lambdas(i);
    for j = 1:numel(input_labels)
      index = find(strcmp(input_labels{j}, labels));
      if ~isempty(index)
        localization(:,:,index) = localization(:,:,index) + ...
                                  component(:,:,j);
      end
    end
  end
  localization = exp(localization);

  [localization, labels] = reorder_labels(localization, labels);
end

function [localization, labels] = reorder_labels(localization, labels)
  reserved_labels = {'null', 'skin', 'hair'};
  reserved_indices = cellfun(@(x)find(strcmp(x,labels)), reserved_labels);
  order = [reserved_indices, setdiff(1:numel(labels), reserved_indices)];
  localization = localization(:,:,order);
  labels = labels(order);
end
