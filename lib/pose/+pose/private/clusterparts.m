function idx = clusterparts(deffeat,K,pa)

R = 100;

idx = cell(1,length(deffeat));
for p = 1:length(deffeat)
	% create clustering feature
  if pa(p) == 0
    i = 1;
    while pa(i) ~= p
      i = i+1;
    end
    X = deffeat{i} - deffeat{p};
  else
    X = deffeat{p} - deffeat{pa(p)}; 
  end
  % try multiple times kmeans
  gInd = cell(1,R);
  cen  = cell(1,R);
  sumdist = zeros(1,R);
  for trial = 1:R
    [gInd{trial} cen{trial} sumdist(trial)] = k_means(X,K(p));
  end
  % take the smallest distance one
  [dummy ind] = min(sumdist);
  idx{p} = gInd{ind(1)};
end