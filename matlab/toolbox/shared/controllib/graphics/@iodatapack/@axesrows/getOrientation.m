function Or = getOrientation(h)
% Fetch orientation from Axes (@plotrows)

%   Copyright 2014 The MathWorks, Inc.

if ishandle(h.Axes)
   Or = h.Axes.Orientation;
else
   Or = '2row';
end
