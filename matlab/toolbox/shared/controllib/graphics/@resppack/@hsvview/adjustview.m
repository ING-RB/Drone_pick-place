function adjustview(this,Data,Event,varargin)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'prelim') clips unbounded branches of the locus
%  using the XFocus and YFocus info in DATA before invoking the limit
%  picker.
%
%  ADJUSTVIEW(VIEW,DATA,'postlimit') restores the full branch extent once  
%  the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%   Copyright 1986-2020 The MathWorks, Inc.
switch Event
   case 'prelim'
      % Prepare plot for limit picker
      hsv = Data.HSV;
      nsv = length(hsv);
      if strcmp(this.AxesGrid.YScale,'linear')
         hsvf = hsv(isfinite(hsv));
         if isempty(hsvf)
            hsvmax = 10;
         else
            hsvmax = 1.25*max(hsvf);
         end
         hsv(1) = hsvmax;
         BaseValue = 0;
      else
         hsvf = hsv(isfinite(hsv) & hsv>0);
         if isempty(hsvf)
            BaseValue = 0.01;
            hsvmax = 100;
         else
            maxhsv = max(hsvf);
            BaseValue = max(0.3*min(hsvf),eps*maxhsv);
            hsvmax = 3*maxhsv;
         end
         hsv(1) = hsvmax;
         hsv(hsv<BaseValue) = NaN;
      end
      
      set(this.FiniteSV,'Xdata',1:nsv,'YData',hsv,'BaseValue',BaseValue)
      set(this.InfiniteSV,'Xdata',NaN,'YData',NaN,'BaseValue',BaseValue)
      set(this.ErrorBnd,'Xdata',NaN,'YData',NaN,'ZData',NaN)

   case 'postlim'
      % Restore branches to their full extent
      draw(this,Data)
end
