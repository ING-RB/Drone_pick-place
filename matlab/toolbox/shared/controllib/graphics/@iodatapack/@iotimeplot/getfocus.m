function xfocus = getfocus(this,xunits)
%GETFOCUS  Computes optimal X limits for time plots.
% 
%   XFOCUS = GETFOCUS(PLOT) merges the time ranges for all 
%   visible curves and returns the time focus in the current
%   time units (X-focus).  XFOCUS controls which portion of the
%   time response is displayed when the x-axis is in auto-range
%   mode.
%
%   XFOCUS = GETFOCUS(PLOT,XUNITS) returns the X-focus in the 
%   time units XUNITS.

%   Copyright 2013 The MathWorks, Inc.

if nargin==1
   xunits = this.AxesGrid.XUnits;
end

if isempty(this.TimeFocus)
   % No user-defined focus. Collect individual focus for all visible
   % waves
   xfocus = NaN(1,2);
   allResp = allwaves(this);
   for ct=1:numel(allResp)
      % For each visible response...
      rct = allResp(ct);
      if rct.isvisible
         data = rct.Data;
         for k=1:numel(data)
            if strcmp(rct.View(k).Visible,'on')
               xfocus = ltipack.mrgfocus([xfocus;data(k).Focus]);
            end
         end
      end
   end
   
   % Finalize
   xfocus = xfocus*tunitconv('seconds',xunits);
   if all(isnan(xfocus))
      xfocus = [0 1];
   elseif xfocus(2)>xfocus(1)
      xfocus(2) = tchop(xfocus(2));
   elseif abs(xfocus(1))<1
      xfocus = [0 1];
   else
      xfocus = xfocus(1) + abs(xfocus(1)) * [-1 1];
   end
else
   xfocus = this.TimeFocus*tunitconv('seconds',xunits);
end
