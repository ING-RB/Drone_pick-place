function draw(this, Data, varargin)
%DRAW  Draws Bode response curves.
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

%  Author(s): P. Gahinet
%  Copyright 1986-2021 The MathWorks, Inc.

% compare/predict plots extend draw method; hence common code moved to
% common_draw method
AxGrid = this.AxesGrid;

% Collect data
[Freq,Mag,Phase] = getPlotData(Data,AxGrid.XScale{1});
% Store underlying (signed) frequency vector (in Data units)
this.Frequency = Freq;

% Draw response in current units
Freq = Freq*funitconv(Data.FreqUnits,AxGrid.XUnits);
Mag = unitconv(Mag,Data.MagUnits,AxGrid.YUnits{1});
Phase = unitconv(Phase,Data.PhaseUnits,AxGrid.YUnits{2});
common_draw(this, Mag, Phase, Freq, Data.Ts)
