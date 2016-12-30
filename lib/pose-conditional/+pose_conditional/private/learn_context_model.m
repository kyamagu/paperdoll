function context_model = learn_context_model(samples)
%LEARN_CONTEXT_MODEL Learn a dictionary of context map.
  context_model = [];
  if isfield(samples, 'context')
    for i = 1:numel(samples)
      context_map = imread_or_decode(samples(i).context, 'png');
      context_model = union(context_model, context_map(:));
    end
    context_model = context_model(context_model ~= 0);
    context_model = accumarray(context_model(:), ...
                               1:numel(context_model), ...
                               [context_model(end), 1]);
  end
end