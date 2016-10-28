function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  ADD_SPECIAL_LABELS = true;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
      case 'KNNRetrieverAddSpecialLabels', ADD_SPECIAL_LABELS = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output)
    return
  end
  
  % Resolve dependency.
  assert(isfield(samples, config.input));

  % Query similar descriptors.
  [retrieved_ids, tag_scores] = query_knn(config, samples);
  
  % Predict tags.
  [samples.(config.output)] = deal([]);
  [samples.(config.output_labels)] = deal([]);
  for i = 1:numel(samples)
    samples(i).(config.output) = retrieved_ids(i,:);
    [ordered_scores, order] = sort(tag_scores(i,:), 'descend');
    predicted_tag_index = order(ordered_scores > config.threshold);
    predicted_tags = config.tags(predicted_tag_index);
    if ADD_SPECIAL_LABELS
      predicted_tags = ['null', 'skin', 'hair', predicted_tags];
    end
    samples(i).(config.output_labels) = predicted_tags;
  end

end