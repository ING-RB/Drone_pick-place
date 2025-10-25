function b = isInsideBbox(bbox, qX, qY)
% true if inside or on boundary of bounding box

%   Copyright 2022 The MathWorks, Inc.

%#codegen

b = (bbox.loX <= qX && qX <= bbox.hiX) && (bbox.loY <= qY && qY <= bbox.hiY);

end
