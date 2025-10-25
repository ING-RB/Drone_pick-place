function box1 = mergeBbox(box1, box2)
% merge two bbox

%   Copyright 2022 The MathWorks, Inc.

%#codegen

box1 = coder.internal.polyshapeHelper.bboxExpand(box1,box2.loX,box2.loY);
box1 = coder.internal.polyshapeHelper.bboxExpand(box1,box2.hiX,box2.hiY);
end
