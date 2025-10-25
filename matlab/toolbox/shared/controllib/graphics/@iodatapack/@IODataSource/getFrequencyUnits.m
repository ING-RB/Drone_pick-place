function Units = getFrequencyUnits(this)
%getFrequencyUnits  Returns Frequency Units.

%  Copyright 2013 The MathWorks, Inc.

TimeUnits = this.getTimeUnits;
FU = this.IOData.getDefaultFrequencyUnit;

if strcmpi(FU,'cycle/TimeUnit')
   if strcmpi(TimeUnits,'seconds')
      Units = 'Hz';
   else
      Units = ['cycle/',TimeUnits(1:end-1)];
   end
elseif strcmpi(FU,'rad/TimeUnit')
   if strcmpi(TimeUnits,'seconds')
      Units = 'rad/s';
   else
      Units = ['rad/',TimeUnits(1:end-1)];
   end
else
   Units = FU;
end
