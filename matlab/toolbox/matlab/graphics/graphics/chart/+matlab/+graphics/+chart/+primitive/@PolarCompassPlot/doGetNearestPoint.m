function index = doGetNearestPoint(obj, position)
%

%  Copyright 2024 The MathWorks, Inc.

% Perform picking against the line segments from the PolarAxes center to
% the data point. This assures that the line segment being hovered over is
% the one that will get a data tip.
segs = createSegments(obj.ThetaDataCache, obj.RDataCache, obj.BaseValue_I);
pickUtils = matlab.graphics.chart.interaction.dataannotatable.picking.AnnotatablePicker.getInstance();
index = pickUtils.nearestSegment(obj, position, true, segs{:});
index = floor((index-1)/3) + 1; % three elements per segment
end

function segs = createSegments(tdata, rdata, basevalue)
% Create a segment from the PolarAxes center to each data point, padded
% with NaNs.
t = repelem(tdata,3);
r = repelem(rdata,3);
r(1:3:end) = basevalue;
r(3:3:end) = NaN;
segs = {t,r};
end