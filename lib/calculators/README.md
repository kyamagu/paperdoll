Calculators
===========

Modular pipeline processors.

Feature calculator
------------------

Feature calculator provides a framework to construct a feature transformation
and other processing pipeline. There are three basic APIs.

    config = feature_calculator.create(...);
    [config, samples] = feature_calculator.train(config, samples);
    samples = feature_calculator.apply(config, samples);

For features not requiring training, the second step can be skipped.

In the create function, you specify desired feature calculation. The
following example shows a pipeline to compute lab color and dense HOG feature.

    config = feature_calculator.create(...
      'lab_calculator', {'Input', 'image', 'Output', 'lab'}, ...
      'dense_hog_calculator', {'Input', 'image', 'Output', 'dense_hog'} ...
      );

The train and apply function takes struct array of data samples. To apply the
above pipeline, one provides a struct array with `image` field so that each
calculator processes the input field.

    samples = struct('image', image_data);
    samples = feature_calculator.apply(config, samples);

After this, the `samples` struct has `lab` and `dense_hog` field filled.

