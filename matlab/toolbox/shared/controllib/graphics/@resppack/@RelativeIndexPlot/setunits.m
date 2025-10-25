function setunits(this,property,value)
% SETUNITS is a method that applies the units to the plot. The units are
% obtained from the view preferences. Since this method is plot specific,
% not all fields of the Units structure are used.


%   Copyright 2015 The MathWorks, Inc.

% Prevent negative data ignore warning when switching between abs/logscale
% to dB
hw = ctrlMsgUtils.SuspendWarnings; %#ok<*NASGU>

switch property
case 'FrequencyUnits'
    if strcmpi(value,'auto')
        this.setAutoFrequencyUnits;
    else
        this.AxesGrid.XUnits = value;
    end
case 'FrequencyScale'
    set(this.AxesGrid,'XScale',{value});
case 'IndexScale'
    set(this.AxesGrid,'YScale',{value});
end
