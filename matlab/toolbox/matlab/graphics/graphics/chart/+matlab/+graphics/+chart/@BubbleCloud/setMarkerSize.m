function setMarkerSize(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Set the size of markers based on the InnerPosition and limits of the
% axes. To set the limits so that the bubbles exactly touch, find the ratio
% of the axes width (in points) to the axes X limits (in data). This
% converts 1 data unit to points, and the radius of the largest bubble is 1
% data unit.

% unitRadius is the radius (in points) of a bubble with radius 1 (in data,
% which is also the largest bubble)
unitRadius = obj.Axes.InnerPosition_I(3)/diff(obj.Axes.XLim_I);

% Clamp unitRadius to positive
unitRadius = max(unitRadius,eps);

obj.Marker.Size=(2*obj.XYR(3,:)*unitRadius);

if obj.SelectedMarkerIndex <= numel(obj.Marker.Size)
    obj.HighlightMarker.Size=obj.Marker.Size(obj.SelectedMarkerIndex);
end
% When the MarkerSize changes, mark labels dirty so that
% lengths can be re-computed
if ~isempty(obj.LabelData_I)
    obj.LabelsDirty=true;
end

% Cache InnerPosition and Limits that were used to set the
% current marker size
obj.InnerPositionCache=obj.Axes.InnerPosition_I;
obj.LimitsCache=[obj.Axes.XLim_I obj.Axes.YLim_I];
end
