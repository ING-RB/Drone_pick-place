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
            this.(property) = value;
        end
        % Draw needs to be called explicitly for Nyquist and Nichols.
        % This is because as a result of changing units when the frequency
        % vector is specified, data is cleared from the cache and the
        % response object.
        % Resolution to Geck 142885
        draw(this);
    case 'PhaseUnits'
        this.AxesGrid.XUnits = value;
end
