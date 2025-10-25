function isValid =  isValidROI(this,figRegionCoords)
% This internal helper function may change in a future release.

% IsValidROI checks if the height or width of the ROI is less than than delta (aprox. 0.05% of the default axes size) ,
% then select nothing and hide the ROI tool.

%  Copyright 2019 The MathWorks, Inc.

delta = 3;
h = abs(figRegionCoords(1,1) - figRegionCoords(1,2)); %ROI height
w = abs(figRegionCoords(2,1) - figRegionCoords(2,4)); %ROI width
isValid = true;
if  h < delta || w < delta
    if ~isempty(this.Graphics) && isvalid(this.Graphics) && strcmp(this.Graphics.Visible,'on')
        this.Graphics.Visible = 'off';
    end
    isValid = false; 
end
end


