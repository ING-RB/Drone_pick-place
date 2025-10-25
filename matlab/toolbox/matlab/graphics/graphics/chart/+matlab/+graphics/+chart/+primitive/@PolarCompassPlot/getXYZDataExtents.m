function extents = getXYZDataExtents(hObj,~,~)
% getXYZDataExtents for PolarCompass

%   Copyright 2024 The MathWorks, Inc.

[xD,yD,~] = matlab.graphics.chart.primitive.utilities.preprocessextents(...
            double(hObj.ThetaDataCache(:)),double(hObj.RDataCache(:)));

% Always pass 0 as the lower value for ylim since the polar origin is 
% automatically at zero unless R-Limits are manually specified.
extents = [min(xD) max(xD); 0 max(abs(yD)); NaN NaN];
end
