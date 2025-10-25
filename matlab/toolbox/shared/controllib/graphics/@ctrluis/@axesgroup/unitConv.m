function Value = unitConv(this, Value,OldUnits,NewUnits)
% Handle all types of unit conversions. This class does not know what type
% of plot it is.  Determine if it should use tunitconv or funitconv else
% resort to old behavior of using unitconv.

% Called by generic_listeners. 

% Copyright 2017 The MathWorks, Inc.

if iscell(NewUnits) && isequal(size(NewUnits),[1 1])
    NewUnits = NewUnits{1};
end

if iscell(OldUnits) && isequal(size(OldUnits),[1 1])
    OldUnits = OldUnits{1};
end

if strcmpi(OldUnits,NewUnits)
    return
end

TimeUnits = controllibutils.utGetValidTimeUnits;
TimeUnits = TimeUnits(:,1);
FrequencyUnits = controllibutils.utGetValidFrequencyUnits;
FrequencyUnits = FrequencyUnits(:,1);

if any(strcmpi(OldUnits,TimeUnits))
    Value = Value*tunitconv(OldUnits,NewUnits);
elseif any(strcmpi(OldUnits,FrequencyUnits))
    Value = Value*funitconv(OldUnits,NewUnits);
else
    Value = unitconv(Value,OldUnits,NewUnits);
end