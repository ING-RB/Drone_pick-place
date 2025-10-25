function adjustview(this,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Author(s): C. Buhr
%  Copyright 1986-2014 The MathWorks, Inc.

%  Frequency:   Nf x 1
%  Singular Values: Nf x Ns
if strcmp(Event,'prelim')
   % To show desired extent to limit picker
   this.draw(Data);
else
   AxGrid = this.AxesGrid;
   Freq = Data.Frequency;
   XData = [Freq;flipud(Freq)] * funitconv(Data.FreqUnits,AxGrid.XUnits);
   ZData = this.ZLevel * ones(size(XData));

   % Mag bound
   YLims = get(ancestor(this.MagPatch,'axes'),'Ylim');
   if strcmpi(this.BoundType,'upper')
      BoundLimit = YLims(2);
   else
      BoundLimit = YLims(1);
   end
   Mag =  unitconv(Data.Magnitude,Data.MagUnits,AxGrid.YUnits{1});
   YData = [Mag;BoundLimit*ones(size(Mag))];  % plot units
   set(double(this.MagPatch), 'XData', XData, 'YData', YData, 'ZData',ZData);
   
   % Phase bound
   YLims = get(ancestor(this.PhasePatch,'axes'),'Ylim');
   if strcmpi(this.BoundType,'upper')
      BoundLimit = YLims(2);
   else
      BoundLimit = YLims(1);
   end
   Phase = unitconv(Data.Phase,Data.PhaseUnits,AxGrid.YUnits{2});   
   YData = [Phase;BoundLimit*ones(size(Phase))];
   set(double(this.PhasePatch), 'XData', XData, 'YData', YData, 'ZData',ZData);
end