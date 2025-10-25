function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might
%  interfer with limit picking.  rDATA contains the data of the parent
%  response.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlimit') adjusts the HG object extent
%  once the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): John Glass
%  Copyright 1986-2010 The MathWorks, Inc.

if strcmp(Event,'postlim')
   % Parent axes and limits
   AxGrid = cv.AxesGrid;
   LOG = strcmp(AxGrid.XScale,'log');
   MagUnits = AxGrid.YUnits{1};
   PhaseUnits = AxGrid.YUnits{2};
   
   % Gain Margin
   ax = cv.MagVLine.Parent;
   XlimMag = get(ax,'Xlim');
   YlimMag = get(ax,'Ylim');
   Wcg = cd.GMFrequency*funitconv(cd.FreqUnits,AxGrid.XUnits);
   if LOG
      XDotMag = abs(Wcg);
   else
      XDotMag = Wcg;
   end
   YDotMag = unitconv(1/cd.GainMargin,'abs',MagUnits);
   ZeroDB = unitconv(1,'abs',MagUnits);
   set(cv.MagVLine,'XData',XDotMag([1 1]),'YData',[ZeroDB, YDotMag])
   % Revisit: If the plot is in abs mode, offset the lower limit by eps to ensure
   % that the limit picker is not broken when the axis scale is put in log
   % mode.
   if strcmpi('abs',MagUnits)
      set(cv.MagAxVLine,'XData',XDotMag([1 1]),'YData',[YlimMag(1)+eps, ZeroDB])
   else
      set(cv.MagAxVLine,'XData',XDotMag([1 1]),'YData',[YlimMag(1), ZeroDB])
   end
   set(cv.ZeroDBLine,'XData',XlimMag,'YData',ZeroDB([1 1]))
  
   % Phase Margin
   ax = cv.PhaseVLine.Parent;
   XlimPhase = get(ax,'Xlim');
   YlimPhase = get(ax,'Ylim');
   Wcp = cd.PMFrequency*funitconv(cd.FreqUnits,AxGrid.XUnits);
   if LOG
      XDotPhase = abs(Wcp);
   else
      XDotPhase = Wcp;
   end
   YDotPhase = unitconv(cd.PhaseMargin,'deg',PhaseUnits);
   PMline = unitconv(180*round((cd.PMPhase-cd.PhaseMargin)/180),'deg',PhaseUnits);
   % Position phase margin objects
   set(cv.PhaseCrossLine,'XData',XlimPhase,'YData',PMline([1 1]))
   set(cv.PhaseVLine,'XData',XDotPhase([1 1]),'YData',[PMline PMline+YDotPhase])
   set(cv.PhaseAxVLine,'XData',XDotPhase([1 1]),'YData',[PMline YlimPhase(2)])
   
   % Set the lines connecting the 0DB and phase crossover to the axes
   set(cv.Phase0DBVLine,'XData',XDotMag([1 1]),'YData',[PMline YlimPhase(2)])
   set(cv.Mag180VLine,'XData',XDotPhase([1 1]),'YData',[YlimMag(1), ZeroDB])
   
   % Build title
   %---Gain text
   GM = unitconv(cd.GainMargin,'abs',MagUnits);
   if strcmp(MagUnits,'abs')
      MagUnits = '';
   else 
      MagUnits = [MagUnits ' '];
   end
   if isfinite(GM)
      MagTxt = sprintf('Gm = %0.3g %s(at %0.3g %s)',GM,MagUnits,Wcg,AxGrid.XUnits);
   else
      MagTxt = 'Gm = Inf';
   end
   
   %---Phase text
   if isfinite(cd.PhaseMargin)
      PhaseTxt = sprintf('Pm = %0.3g %s (at %0.3g %s)',...
         YDotPhase,PhaseUnits,Wcp,AxGrid.XUnits);
   else
      PhaseTxt = 'Pm = Inf';
   end
   
   %% Revisit axesgrid.Title property does not take a cell array
   if strcmp(AxGrid.TitleMode,'auto')
       AxGrid.Title = sprintf('%s\n%s,  %s',...
           getString(message('Controllib:plots:strBodeDiagram')),MagTxt,PhaseTxt);
   end
end
