function rectified_image = rectify(im, boxes, reference)
%RECTIFY Rectify the image according to the pose detection.
%
%    im:    image data.
%    boxes: UCI format detection boxes.
%    reference: scalar struct
%        points:  UCI format point array [x,y;...]
%        width:   Width of the reference frame
%        height:  Height of the reference frame
%        parents: Indices of parents for each point
%
% Kota Yamaguchi 2013

  scale = 0.15;
  [XI, YI] = meshgrid(1:reference.width, 1:reference.height);
  control_points = compute_control_points(unpack_boxes(boxes),...
                                          size(im),...
                                          reference.parents,...
                                          scale);
  reference_points = compute_reference_points(reference,...
                                              reference.parents,...
                                              scale);
  map_x = griddata(reference_points(:,1), reference_points(:,2), ...
                   control_points(:,1), XI, YI);
  map_y = griddata(reference_points(:,1), reference_points(:,2), ...
                   control_points(:,2), XI, YI);
  assert(~any(isnan(map_x(:))) && ~any(isnan(map_x(:))));
  map_x = max(map_x, 1);
  map_x = min(map_x, size(im,2));
  map_y = max(map_y, 1);
  map_y = min(map_y, size(im,1));
  
  rectified_image = zeros([size(map_x),size(im,3)]);
  for i = 1:size(im, 3)
    rectified_image(:,:,i) = interp2(im2double(im(:,:,i)), map_x, map_y, 'cubic');
  end

end

function boxes = unpack_boxes(pos)
%UNPACK_BOXES Return boxes in row vector format [x1,y1,x2,y2;...].
  if isempty(pos), error('Empty control points'); end
  assert(size(pos,1)==1);
  boxes = reshape(pos(1:end-2),[4,(numel(pos)-2)/4])';
end

function points = compute_control_points(boxes, siz, parents, scale)
%POSE_BOX Convert packed pose data into control points.
  corners = [min(boxes(:,1:2),[],1), max(boxes(:,3:4),[],1)];
  corner_points = [...
    corners(1), corners(2);...
    corners(1), corners(4);...
    corners(3), corners(2);...
    corners(3), corners(4);...
    ];
  % Expand lines to rectangles.
  centers = .5*(boxes(:,1:2) + boxes(:,3:4));
  cpoints = cell(size(centers,1),1);
  for i = 2:numel(parents)
    x1 = centers(i,:);
    x2 = centers(parents(i),:);
    dx = x2 - x1;
    dx_orth = scale * [-dx(2),dx(1)];
    cpoints{i} = [...
      x1 + dx_orth;...
      x2 + dx_orth;...
      x2 - dx_orth;...
      x1 - dx_orth;...
      ];
  end
  cpoints = cat(1, cpoints{:});
  % Add tight bounding box.
  xymin = min(cpoints,[],1);
  xymax = max(cpoints,[],1);
  tight_corner_points = [...
    xymin; xymin(1),xymax(2); xymax(1),xymin(2); xymax;...
    ];
  % Finish and crop.
  points = cat(1,cpoints,tight_corner_points,corner_points);
  points(:,1) = max(points(:,1), 1);
  points(:,1) = min(points(:,1), siz(2));
  points(:,2) = max(points(:,2), 1);
  points(:,2) = min(points(:,2), siz(1));
end

function points = compute_reference_points(reference, parents, scale)
%COMPUTE_REFERENCE_POINTS Convert reference data into control points.
  corner_points = [...
    1,1; ...
    1, reference.height; ...
    reference.width, 1; ...
    reference.width, reference.height;...
    ];
  % Expand lines to rectangles.
  centers = reference.points(:,1:2);
  cpoints = cell(size(centers,1),1);
  for i = 2:numel(parents)
    x1 = centers(i,:);
    x2 = centers(parents(i),:);
    dx = x2 - x1;
    dx_orth = scale * [-dx(2),dx(1)];
    cpoints{i} = [...
      x1 + dx_orth;...
      x2 + dx_orth;...
      x2 - dx_orth;...
      x1 - dx_orth;...
      ];
  end
  cpoints = cat(1, cpoints{:});
  % Add tight bounding box.
  xymin = min(centers,[],1);
  xymax = max(centers,[],1);
  tight_corner_points = [...
    xymin; xymin(1),xymax(2); xymax(1),xymin(2); xymax;...
    ];
  points = cat(1,cpoints,tight_corner_points,corner_points);
end
