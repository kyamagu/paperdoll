function ranks = pagerank(M, damping)
%PAGERANK  compute PageRank value from the adjacency matrix V
%
%    M: adjacency matrix. M(i, j) represents an edge from j to i.
%    damping: damping parameter [0,1] for the pagerank. default 0.9.
%

if size(M, 1) ~= size(M, 2), error('Adjacency matrix must be square'); end
if nargin < 2, damping = 0.9; end

nodes = size(M, 1);
logger('PageRank: nodes=%d, damping=%f', nodes, damping);

% Make self-loop at dangling nodes
M = M + diag(sum(M, 1) == 0);

% Normalize adjacency matrix
M = M * diag(sparse(1./full(sum(M, 1)))); % normalization

% Compute ranks
tolerance = 1e-8;
ranks = ones(nodes, 1) / nodes;
sum_abs_diff = 1;
count = 1;
while sum_abs_diff > tolerance
    logger('iter %d: tol = %d, sum = %f', count, sum_abs_diff, sum(ranks));
    prev_r = ranks;
    ranks = damping * (full(M * ranks)) + (1 - damping) / nodes;
    sum_abs_diff = sum(abs(ranks - prev_r));
    count = count + 1;
end

end

