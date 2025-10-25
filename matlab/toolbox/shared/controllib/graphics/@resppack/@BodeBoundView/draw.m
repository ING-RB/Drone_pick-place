function draw(this, Data,~)
%DRAW  Draw method for the @BodeBoundView class.

%   Copyright 1986-2014 The MathWorks, Inc.
AxGrid = this.AxesGrid;
Freq = Data.Frequency;
XData = [Freq;flipud(Freq)] * funitconv(Data.FreqUnits,AxGrid.XUnits);
ZData = this.ZLevel * ones(size(XData));

% For limit picker, draw a ribbon centered on the edge of the bound
% Mag bound
Mag = Data.Magnitude;
YData = [1.5*Mag;flipud(Mag)/1.5];  % abs
set(double(this.MagPatch), 'XData', XData, ...
   'YData', unitconv(YData,Data.MagUnits,AxGrid.YUnits{1}),...
   'ZData',ZData);
% Phase bound
Phase = Data.Phase;
YData = [Phase+0.087;flipud(Phase)-0.087];  % rad
set(double(this.PhasePatch), 'XData', XData, ...
   'YData', unitconv(YData,Data.PhaseUnits,AxGrid.YUnits{2}),...
   'ZData',ZData);