function evaluation = evaluate(truths, predictions)
%EVALUATE Evaluate regression performance.
  evaluation = struct;
  evaluation = compute_correlations(evaluation, truths, predictions);
  evaluation = compute_error_stat(evaluation, truths, predictions);
end

function evaluation = compute_correlations(evaluation, X1, X2)
%COMPUTE_CORRELATIONS
  types = {'Pearson', 'Kendall', 'Spearman'};
  for j = 1:numel(types)
    [c_matrix, p_matrix] = corr(X1, X2, 'type', types{j});
    evaluation.(lower(types{j})) = diag(c_matrix)';
    evaluation.([lower(types{j}), '_p']) = diag(p_matrix)';
  end
end

function evaluation = compute_error_stat(evaluation, truths, predictions)
%COMPUTE_ERROR_STAT
  evaluation.mse = sum((truths - predictions).^2, 1) / size(truths, 1);
  [ttest_result.h, ttest_result.p, ttest_result.ci, ttest_result.stats] = ...
    ttest(truths - predictions);
  evaluation.error_ttest = ttest_result;
end