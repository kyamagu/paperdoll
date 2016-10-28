function samples = decode(samples, fields)
%DECODE_FEATURES Decode encoded features.

  if nargin < 2
    fields = fieldnames(samples);
  end
  if ischar(fields), fields = {fields}; end
  fields = intersect(fields, fieldnames(samples));
  for i = 1:numel(samples)
    for j = 1:numel(fields)
      value = samples(i).(fields{j});
      if isstruct(value) && ...
          isfield(value, 'scale') && ...
          isfield(value, 'bias') && ...
          isfield(value, 'data')
        samples(i).(fields{j}) = decode_3d_array(value);
      end
    end
  end

end