function evaluation = evaluate(truths, predictions, varargin)
%EVALUATE Evaluate classification performance.
  truths = truths(:);
  predictions = predictions(:);
  assert(numel(truths) == numel(predictions));
  if islogical(truths) || ...
     islogical(predictions) || ...
     all(unique([truths; predictions]) == [false; true])
    evaluation = evaluate_binary(truths, predictions, varargin{:});
  else
    evaluation = evaluate_categorical(truths, predictions, varargin{:});
  end
end

function evaluation = evaluate_binary(truths, predictions, varargin)
%EVALUATE_BINARY Evaluate binary classification.
  tp = nnz(truths ==  true & predictions ==  true);
  fp = nnz(truths == false & predictions ==  true);
  fn = nnz(truths ==  true & predictions == false);
  tn = nnz(truths == false & predictions == false);
  evaluation = struct(...
    'tp', tp,...
    'fp', fp,...
    'fn', fn,...
    'tn', tn,...
    'accuracy',  (tp + tn) / (tp + fp + fn + tn),...
    'precision', tp / (tp + fp),...
    'recall',    tp / (tp + fn),...
    'f1',        2 * tp / (2 * tp + fp + fn)...
    );
end

function evaluation = evaluate_categorical(truths, predictions, varargin)
%EVALUATE_CATEGORICAL Evaluate categorical classification.
  unique_values = unique([truths; predictions]);
  truths = arrayfun(@(x)find(unique_values==x,1), truths);
  predictions = arrayfun(@(x)find(unique_values==x,1), predictions);
  confusion_matrix = accumarray([truths(:), predictions(:)], 1, ...
                                [numel(unique_values), numel(unique_values)]);
  evaluation.labels = unique_values;
  evaluation.confusion_matrix = confusion_matrix;
  evaluation.accuracy = sum(diag(confusion_matrix)) / sum(confusion_matrix(:));
  evaluation.precision = diag(confusion_matrix)' ./ sum(confusion_matrix, 1);
  evaluation.recall = diag(confusion_matrix)' ./ sum(confusion_matrix, 2)';
  evaluation.f1 = 2 * diag(confusion_matrix)' ./ ...
                  (sum(confusion_matrix, 1) + sum(confusion_matrix, 2)');
  evaluation.average_precision = mean(evaluation.precision);
  evaluation.average_recall = mean(evaluation.recall);
  evaluation.average_f1 = mean(evaluation.f1);
end