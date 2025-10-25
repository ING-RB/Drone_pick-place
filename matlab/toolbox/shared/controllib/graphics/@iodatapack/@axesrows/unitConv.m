function Value = unitConv(this,Value,OldUnits,NewUnits)
% Handle all types of unit conversions. This class does not know what type
% of plot it is.  Determine if it should use tunitconv or funitconv else
% resort to old behavior of using unitconv.

% Copyright 2017 The MathWorks, Inc.

if strcmpi(OldUnits,NewUnits)
    return
end

% Adding support to DatetimeRuler and DurationRuler. The unit conversion is
% done through ruler properties. Will not convert unit when Value is
% datetime or duration.
if(~isduration(Value) && ~isdatetime(Value))
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
end
