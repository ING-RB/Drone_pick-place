function setunits(this,property,value)
% SETUNITS is a method that applies the units to the plot. The units are
% obtained from the view preferences. Since this method is plot specific,
% not all fields of the Units structure are used.

%   Authors: Kamesh Subbarao
%   Copyright 1986-2007 The MathWorks, Inc.


switch property
    case 'TimeUnits'
        if strcmpi(value,'auto')
            this.setAutoTimeUnits;
        else
            this.AxesGrid.XUnits = value;
        end
end

