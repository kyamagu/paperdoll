function samples = encode(samples, fields)
%ENCODE_FEATURES Encode feature struct.

  if nargin < 2
    fields = fieldnames(samples);
  end
  if ischar(fields), fields = {fields}; end
  fields = intersect(fields, fieldnames(samples));
  for i = 1:numel(samples)
    for j = 1:numel(fields)
      value = samples(i).(fields{j});
      if (isnumeric(value) || islogical(value)) && ...
          ~isempty(value) && ~isvector(value)
        samples(i).(fields{j}) = encode_3d_array(value);
      end
    end
  end

end
