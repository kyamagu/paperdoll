function boxes = testmodel(name,model,test,thresh)
% boxes = testmodel(name,model,test,suffix)
% Returns candidate bounding boxes after non-maximum suppression

suffix = [];
if nargin < 4, thresh = model.thresh; end

try
  load([cachedir name '_boxes_' suffix]);
catch
  boxes = cell(1,length(test));
  for i = 1:length(test)
    fprintf([name ': testing: %d/%d\n'],i,length(test));
    im = imread(test(i).im);
    box = detect_fast(im,model,thresh);
    boxes{i} = nms(box,0.3);
  end

  save([cachedir name '_boxes_' suffix], 'boxes','model');
end
