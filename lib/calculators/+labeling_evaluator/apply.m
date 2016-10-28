function samples = apply( config, samples, varargin )
%APPLY Apply feature transform.

  assert(isstruct(config));
  assert(isstruct(samples));

  % Get options.
  FORCE = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'Force', FORCE = varargin{i+1};
    end
  end
  
  % Quit if it's already there.
  if ~FORCE && isfield(samples, config.output_evaluation)
    return
  end
  
  assert(numel(config.input_labels) == numel(config.input));
  assert(numel(config.input) == numel(config.output));
    
  % Compute gradient feature.
  labels = reorder_labels(samples(1).(config.annotation_labels));
  for i = 1:numel(samples)
    annotation = imdecode(samples(i).(config.annotation));
    annotation = reorder_labeling(annotation, ...
                                  samples(i).(config.annotation_labels), ...
                                  labels);
    evaluations = cell(size(config.input));
    for j = 1:numel(config.input)
      labeling = reorder_labeling(samples(i).(config.input{j}), ...
                                  samples(i).(config.input_labels{j}), ...
                                  labels);
      evaluations{j} = compute_performance(annotation, labeling, labels);
      samples(i).(config.output{j}) = imencode(labeling);
    end
    evaluations = [evaluations{:}];
    [evaluations.name] = deal(config.input{:});
    samples(i).(config.annotation_labels) = labels;
    samples(i).(config.annotation) = imencode(annotation);
    samples(i).(config.output_evaluation) = evaluations;
  end

end

function labels = reorder_labels(labels)
%REORDER_LABELS
  reserved_labels = {'null', 'skin', 'hair'};
  labels = [reserved_labels, setdiff(labels, reserved_labels)];
end

function ordered_labeling = reorder_labeling(labeling, labels, reference_labels)
%REORDER_LABELING
  labeling = imread_or_decode(labeling);
  ordered_labeling = zeros(size(labeling), 'uint8');
  for i = 1:numel(labels)
    label_index = find(strcmp(labels{i}, reference_labels));
    if isempty(label_index)
      warning('labelingEvaluator:labelNotFound', ...
              'label "%s" not found in reference.', labels{i});
    else
      ordered_labeling(labeling == i) = label_index;
    end
  end
end

function evaluation = compute_performance(annotation, prediction, labels)
%COMPUTE_PERFORMANCE
  confusion_matrix = accumarray([annotation(:), prediction(:)], 1, ...
                                [numel(labels), numel(labels)]);
  evaluation.confusion_matrix = confusion_matrix;
  evaluation.accuracy = sum(diag(confusion_matrix)) / sum(confusion_matrix(:));
  evaluation.fg_accuracy = sum(diag(confusion_matrix(2:end,2:end))) / ...
                           sum(sum(confusion_matrix(2:end,:)));
  evaluation.precision = diag(confusion_matrix)' ./ sum(confusion_matrix, 1);
  evaluation.recall = diag(confusion_matrix)' ./ sum(confusion_matrix, 2)';
  evaluation.f1 = 2 * diag(confusion_matrix)' ./ ...
                  (sum(confusion_matrix, 1) + sum(confusion_matrix, 2)');
  evaluation.average_precision = mean(evaluation.precision(~isnan(evaluation.precision)));
  evaluation.average_recall = mean(evaluation.recall(~isnan(evaluation.recall)));
  evaluation.average_f1 = mean(evaluation.f1(~isnan(evaluation.f1)));
end