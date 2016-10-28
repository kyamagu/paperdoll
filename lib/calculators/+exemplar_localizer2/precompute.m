function samples = precompute(config, samples, varargin)
%PRECOMPUTE Precompute subsampled label-feature pairs.
%
%   sample = exemplar_localizer2.precompute(config, sample)
%
  for i = 1:numel(samples)
    sample = feature_calculator.decode(samples(i), config.input);
    %labels = sample.(config.exemplar_labels);
    annotation = uint8(imread_or_decode(sample.(config.input_annotation)));
    annotation = annotation(:);
    flattened_features = flatten(config, sample);
    assert(numel(annotation) == size(flattened_features, 1));
    % Keep non-zero pixels.
    flattened_features = flattened_features(annotation(:) ~= 0, :);
    annotation = annotation(annotation ~= 0);
    % Subsample.
    [annotation, features] = subsample_features(annotation, ...
                                                flattened_features, ...
                                                config.sampling_rate, ...
                                                'Alpha', config.sampling_alpha, ...
                                                varargin{:});
    % Save annotation and features.
    samples(i).(config.exemplar_annotation) = annotation;
    samples(i).(config.exemplar_features) = single(features);
  end
end