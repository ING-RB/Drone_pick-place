function draw(this, Data,~)
%DRAW  Draw method for the @sigmaview class (Singular Value Plots).

%  Copyright 1986-2021 The MathWorks, Inc.

AxGrid = this.AxesGrid;
if Data.Ts
   nf = pi/abs(Data.Ts)*funitconv('rad/s',AxGrid.XUnits);
else
   nf = NaN;
end
LOG = strcmp(AxGrid.XScale{1},'log');

% Access data
[Freq,Index] = getPlotData(Data,AxGrid.XScale{1});
% Store underlying (signed) frequency vector in Data units
this.Frequency = Freq;

% Plot 
if LOG
   Freq = abs(Freq);
end
Freq = Freq*funitconv(Data.FreqUnits,AxGrid.XUnits);
Index = unitconv(Index,Data.IndexUnits,AxGrid.YUnits);

% Plot index (note: index values can go negative)
set(double(this.Curves), 'XData', Freq, 'YData', Index);

% Nyquist lines (invisible to limit picker)
YData = unitconv(infline(-Inf,Inf),'abs',AxGrid.YUnits);
XData = nf(:,ones(size(YData)));
if ~LOG
   XData = [-XData NaN XData];  YData = [YData NaN YData];
end
set(this.NyquistLine,'XData',XData,'YData',YData)
