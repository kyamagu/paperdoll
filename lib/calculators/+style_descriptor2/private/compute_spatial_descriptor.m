function raw_descriptor = compute_spatial_descriptor(config, sample)
%COMPUTE Compute pose-dependent descriptor from the given features.
  projectfun = str2func([config.quantizer.name, '.project']);
  poolfun = str2func([config.quantizer.name, '.pool']);
  dense_feature = get_dense_features(config, sample);
  projected_feature = projectfun(config.quantizer, dense_feature);
  keypoints = get_keypoints(sample.(config.input_pose));
  cell_size = config.patch_size ./ config.grid_size;
  raw_descriptor = make_spatial_descriptors(projected_feature, ...
                                            keypoints, ...
                                            poolfun, ...
                                            'CellSize', cell_size, ...
                                            'GridSize', config.grid_size);
  raw_descriptor = raw_descriptor(:)';
end

