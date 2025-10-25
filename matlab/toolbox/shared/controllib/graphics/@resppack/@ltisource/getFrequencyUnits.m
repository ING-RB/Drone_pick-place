function FrequencyUnits = getFrequencyUnits(this)
%getFrequencyUnits  Returns Frequency Units.

%  Copyright 1986-2010 The MathWorks, Inc.

TimeUnits = this.getTimeUnits;

if isa(this.Model,'FRDModel')
    if strcmpi(this.Model.FrequencyUnit,'cycle/TimeUnit')
        if strcmpi(TimeUnits,'seconds')
            FrequencyUnits = 'Hz';
        else
            FrequencyUnits = ['cycle/',TimeUnits(1:end-1)];
        end
    elseif strcmpi(this.Model.FrequencyUnit,'rad/TimeUnit')
        if strcmpi(TimeUnits,'seconds')
            FrequencyUnits = 'rad/s';
        else
            FrequencyUnits = ['rad/',TimeUnits(1:end-1)];
        end
    else
        FrequencyUnits = this.Model.FrequencyUnit;
    end
else
    if strcmpi(TimeUnits,'seconds')
        FrequencyUnits = 'rad/s';
    else 
        FrequencyUnits = ['rad/',TimeUnits(1:end-1)];
    end
    
end