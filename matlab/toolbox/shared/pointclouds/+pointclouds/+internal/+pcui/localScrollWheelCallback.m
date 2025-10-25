%--------------------------------------------------------------------------
% Scroll wheel zoom
%--------------------------------------------------------------------------
function localScrollWheelCallback(~,evt,hFigure)
% Scroll wheel zoom callback

%   Copyright 2019-2020 The MathWorks, Inc.
currentAxes = get(hFigure,'CurrentAxes');

isGeoAxes = isa(currentAxes,'matlab.graphics.axis.GeographicAxes'); % g2409093
if isGeoAxes
    return;
end

if strcmp(currentAxes.Projection, 'orthographic')
    zoomlevel = 0.9;
    if evt.VerticalScrollCount < 0
        camzoom(currentAxes,1/zoomlevel);
    elseif evt.VerticalScrollCount > 0
        camzoom(currentAxes,zoomlevel);
    end
else
    sign = evt.VerticalScrollCount/abs(evt.VerticalScrollCount);
    dist = -sign * 0.1;

    viewAngle = currentAxes.CameraViewAngle;

    camdolly(currentAxes,0,0,dist,'targetmode','fixtarget');
    currentAxes.CameraViewAngle = viewAngle;
    
end

