function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfere  
%  with limit picking.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once  
%  the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2010 The MathWorks, Inc.
if ~isempty(cv.MagPoints) && strcmpi(Event,'postlim')
   % Clear all data
   set(double([cv.MagPoints;cv.PhasePoints]),'xdata',NaN, 'ydata', NaN)
   rData = cd.Parent;
   if isempty(rData.Magnitude)
      % NaN system
      return
   end
   AxGrid = cv.AxesGrid;
   Freq = rData.Frequency*funitconv(rData.FreqUnits,AxGrid.XUnits);
   Mag = unitconv(rData.Magnitude,rData.MagUnits,AxGrid.YUnits{1});
   Phase = unitconv(rData.Phase,rData.PhaseUnits,AxGrid.YUnits{2});
   DMFreq = cd.DMFrequency*funitconv(cd.FreqUnits,AxGrid.XUnits);
   
   % Axis limits
   XlimG = get(cv.MagPoints(1).Parent,'Xlim');
   XlimP = get(cv.PhasePoints(1).Parent,'Xlim');
   
   % Gain margin
   if isfinite(cd.GainMargin)
      if DMFreq>=XlimG(1) && DMFreq<=XlimG(2)
         % Gain margin dots in scope
         YDot = unitconv(cd.GainMargin,'abs', AxGrid.YUnits{1});
         set(double(cv.MagPoints),'XData',DMFreq,'YData',YDot,...
            'MarkerFaceColor',cv.MagPoints.Color)
      else
         % Display as open circles
         XDot = min(max(DMFreq,XlimG(1)),XlimG(2));
         if strcmp(AxGrid.XScale,'log')
            YDot = utInterp1(log(Freq),Mag,log(XDot));
         else
            YDot = utInterp1(Freq,Mag,XDot);
         end
         set(double(cv.MagPoints),'XData',XDot,'YData',YDot,...
            'MarkerFaceColor','none')
      end
   end
   
   % Phase margin
   if isfinite(cd.PhaseMargin)
      if DMFreq>=XlimP(1) && DMFreq<=XlimP(2)
         % Phase margin dots in scope
         YDot = unitconv(cd.PhaseMargin,'deg', AxGrid.YUnits{2});
         set(double(cv.PhasePoints),'XData',DMFreq,'YData',YDot,...
            'MarkerFaceColor',cv.PhasePoints.Color)
      else
         % Display as open circles
         XDot = min(max(DMFreq,XlimP(1)),XlimP(2));
         YDot = utInterp1(Freq,Phase,XDot);
         set(double(cv.PhasePoints),'XData',XDot,'YData',YDot,...
            'MarkerFaceColor','none')
      end
   end
end