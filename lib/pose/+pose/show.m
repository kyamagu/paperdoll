function show( im, boxes, pa )
%SHOW Display pose with an image
%
%    pose.show(im, boxes)
%    pose.show(im, boxes, model.pa)
%

  colorset = {'g','g','y','m','m','m','m','y','y','y','r','r','r','r','y',...
              'c','c','c','c','y','y','y','b','b','b','b'};
  if isstruct(boxes)
    boxes = [boxes.x1(:)';boxes.y1(:)';boxes.x2(:)';boxes.y2(:)'];
    boxes = [boxes(:)',1,0];
  end
  if isempty(boxes)
    showboxes(im, [], colorset);
  elseif nargin < 3
    showboxes(im, boxes(1,:), colorset); % show the best detection
  else
    showskeletons(im, boxes(1,:), colorset, pa);
  end

end

