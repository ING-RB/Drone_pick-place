function pt = doGetReportedPosition(obj, index, ~)
%

%  Copyright 2024 The MathWorks, Inc.

% Get the actual position by getting the anchor position
pt = doGetDisplayAnchorPoint(obj, index, 0);
end
