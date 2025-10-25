function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfer  
%  with limit picking.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlimit') adjusts the HG object extent once  
%  the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%   Author(s): J. Glass, P. Gahinet
%   Copyright 1986-2010 The MathWorks, Inc.


if strcmp(Event,'postlim')
   % Position dot and lines given finalized axes limits
   AxGrid = cv.AxesGrid;
   Xauto = strcmp(AxGrid.XlimMode,'auto');
   rData = cd.Parent;
   FreqFactor = funitconv(rData.FreqUnits,cv.AxesGrid.XUnits);
   Freq = FreqFactor * rData.Frequency;
   
   % Position dot and lines given finalized axes limits
   ax = cv.Points.Parent;
   Xlim = get(ax,'Xlim');
   Ylim = get(ax,'Ylim');
   LOG = strcmp(ax.XScale,'log');
   
   XDot = FreqFactor * cd.Frequency;
   if LOG
      SIGN = sign(XDot);  XDot = abs(XDot);
   end
   OutScope = Xauto && (XDot<Xlim(1) || XDot>Xlim(2));
   if OutScope && numel(Freq)>1
      % Dot falls outside auto limit box
      XDot = max(Xlim(1),min(Xlim(2),XDot));
      YData = rData.Index;
      if LOG
         ind = find(SIGN*Freq>0);
         YDot = utInterp1(log(abs(Freq(ind))),YData(ind),log(XDot));
      else
         YDot = utInterp1(Freq,YData,XDot);
      end
      Color = get(ax,'Color');   % open circle
   else
      YDot = cd.MinIndex;
      Color = get(cv.Points,'Color');
   end
   
   if OutScope || isnan(XDot)
      set(double([cv.HLines,cv.VLines]),'XData',[NaN NaN],'YData', [NaN NaN])
   else
      set(double(cv.HLines),'XData',[Xlim(1),XDot],'YData',[YDot,YDot])
      set(double(cv.VLines),'XData',[XDot XDot],'YData',[Ylim(1) YDot])
   end
   % Position dots
   set(double(cv.Points),'XData',XDot,'YData',YDot,'MarkerFaceColor',Color)
end

