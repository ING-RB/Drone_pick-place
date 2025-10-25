function pt = doGetDisplayAnchorPoint(obj, index, ~)
%

%  Copyright 2024 The MathWorks, Inc.

numPoints = numel(obj.ThetaData_I);
if index>0 && index<=numPoints
    pt = [double(obj.ThetaData_I(index)) double(obj.RData_I(index)) 0];
else
    pt = [NaN NaN NaN];
end
pt = matlab.graphics.shape.internal.util.SimplePoint(pt);

end