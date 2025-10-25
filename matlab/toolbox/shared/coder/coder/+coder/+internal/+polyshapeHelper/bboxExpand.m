function bbox = bboxExpand(bbox, qX, qY)
% Add input point (qX, qY) to bounding box

%   Copyright 2022 The MathWorks, Inc.

%#codegen

if bbox.loX > qX
    bbox.loX = qX;
end
if bbox.loY > qY
    bbox.loY = qY;
end
if bbox.hiX < qX
    bbox.hiX = qX;
end
if bbox.hiY < qY
    bbox.hiY = qY;
end