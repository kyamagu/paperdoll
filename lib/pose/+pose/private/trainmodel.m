function model = trainmodel(name,pos,neg,varargin)

% --------------------
% specify model parameters
% number of mixtures for 26 parts
K = [6 6 6 6 6 6 6 6 6 6 6 6 6 6 ...
         6 6 6 6 6 6 6 6 6 6 6 6]; 
% Tree structure for 26 parts: pa(i) is the parent of part i
% This structure is implicity assumed during data preparation
% (PARSE_data.m) and evaluation (PARSE_eval_pcp)
pa = [0 1 2 3 4 5 6 3 8 9 10 11 12 13 2 15 16 17 18 15 20 21 22 23 24 25];
% Spatial resolution of HOG cell, interms of pixel width and hieght
% The PARSE dataset contains low-res people, so we use low-res parts
sbin = 4;

pos = point2box(pos,pa);

file = [cachedir name '.log'];
delete(file);
diary(file);

cls = [name '_cluster_' num2str(K')'];
try
  load([cachedir cls]);
catch
  model = initmodel(pos,sbin);
  def = data_def(pos,model);
  idx = clusterparts(def,K,pa);
  save([cachedir cls],'def','idx');
end

for p = 1:length(pa)
  cls = [name '_part_' num2str(p) '_mix_' num2str(K(p))];
  try
    load([cachedir cls]);
  catch
    sneg = neg(1:min(length(neg),100));
    model = initmodel(pos,sbin);
    models = cell(1,K(p));
    for k = 1:K(p)
      spos = pos(idx{p} == k);
      for n = 1:length(spos)
        spos(n).x1 = spos(n).x1(p);
        spos(n).y1 = spos(n).y1(p);
        spos(n).x2 = spos(n).x2(p);
        spos(n).y2 = spos(n).y2(p);
      end
      models{k} = train(cls,model,spos,sneg,1,1);
    end
    model = mergemodels(models);
    save([cachedir cls],'model');
  end
end

cls = [name '_final1_' num2str(K')'];
try
  load([cachedir cls]);
catch
  model = buildmodel(name,model,def,idx,K,pa);
  for p = 1:length(pa)
		for n = 1:length(pos)
			pos(n).mix(p) = idx{p}(n);
		end
	end
  model = train(cls,model,pos,neg,0,1);
  save([cachedir cls],'model');
end

cls = [name '_final_' num2str(K')'];
try
 load([cachedir cls]);
catch
 if isfield(pos,'mix')
   pos = rmfield(pos,'mix');
 end
 model = train(cls,model,pos,neg,0,1);
 save([cachedir cls],'model');
end
