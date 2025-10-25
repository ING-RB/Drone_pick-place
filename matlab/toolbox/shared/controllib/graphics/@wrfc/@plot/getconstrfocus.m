function xfocus = getconstrfocus(this,xunits) 
% GETCONSTRFOCUS return the xfocus for requirements displayed on the plot
%

% Note: method should be protected not public
%
 
% Author(s): A. Stothert 23-Apr-2010
% Copyright 2009-2010 The MathWorks, Inc.

%Collect xrange from each requirement
xfocus = NaN(1,2);
%Remove any stale requirements that may have been deleted
this.Requirements(~ishandle(this.Requirements)) = [];
for ct = 1:numel(this.Requirements)
   hR = this.Requirements(ct);
   if strcmp(get(hR.Elements,'Visible'),'on')
      extent       = hR.extent;
      fR = LocalUnitConv(extent(1:2),hR.getDisplayUnits('xunits'),xunits);
      xfocus = [min(xfocus(1),fR(1)) , max(xfocus(2),fR(2))];
   end
end
end



function Value = LocalUnitConv(Value,OldUnits,NewUnits)
% Handle all types of unit conversions. This class does not know what type
% of plot it is.  Determine if it should use tunitconv or funitconv else
% resort to old behavior of using unitconv.


% Temporary fix until all of units work is done
% Begin
if strcmpi(OldUnits,'rad/sec')
    OldUnits = 'rad/s';
end

if strcmpi(NewUnits,'rad/sec')
    NewUnits = 'rad/s';
end
% End


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
end