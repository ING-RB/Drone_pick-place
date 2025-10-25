function pt = doGetDisplayAnchorPoint(obj, index, ~)
%doGetDisplayAnchorPoint Get the data point to display a datatip at
%
%  doGetDisplayAnchorPoint(obj, index, factor) returns a data coordinate
%  where the datatip should be displayed for the specified data index.

%  Copyright 2024 The MathWorks, Inc.

verts = obj.DataTipsVertexData;
% Find the anchor point using input index
pt = [verts(index,1:2) 0];

% Return a "SimplePoint" object
pt = matlab.graphics.shape.internal.util.SimplePoint(pt);
end
