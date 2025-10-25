function setunits(this,property,value)
% SETUNITS is a method that applies the units to the plot. The units are
% obtained from the view preferences. Since this method is plot specific,
% not all fields of the Units structure are used.

%   Authors: Kamesh Subbarao
%   Copyright 1986-2004 The MathWorks, Inc.

switch property
    case 'FrequencyUnits'
        if strcmpi(value,'auto')
            this.setAutoFrequencyUnits;
        else
            this.FrequencyUnits = value;
        end
        draw(this);
    case 'TimeUnits'
        if strcmpi(value,'auto')
            this.setAutoTimeUnits;
        else
            this.TimeUnits = value;
        end
        draw(this);
end