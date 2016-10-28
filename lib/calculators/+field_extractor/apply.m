function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));
  
  % Extract specified fields.
  input_fields = fieldnames(samples);
  fields_to_remove = setdiff(input_fields, config.output);
  for i = 1:numel(fields_to_remove)
    samples = rmfield(samples, fields_to_remove{i});
  end
end