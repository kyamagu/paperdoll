Classifier
==========

Classifier module. Currently liblinear and libsvm wrappers are implemented.

Example
=======

    classifier = linear_classifier.train(labels, samples);
    [predictions, probabilities] = linear_classifier.predict(samples);
