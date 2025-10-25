function str = maketip(~,~,info,~)
%MAKETIP  Build data tips for MinDiskMarginView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2020 The MathWorks, Inc.

AxGrid = info.View.AxesGrid;
r = info.Carrier;
fUnits = AxGrid.XUnits;
DM = sprintf('%0.3g',info.Data.DiskMargin);
DMFreq = info.Data.DMFrequency*funitconv(info.Data.FreqUnits,fUnits);
FData = sprintf('%0.3g',DMFreq);

str{1,1} = getString(message('Controllib:plots:strResponseLabel',r.Name));
if info.MarginType == 1
   % Convert Gain Margin from abs to Axis Grid YUnits{1}
   mUnits = AxGrid.YUnits{1};
   YData = unitconv(info.Data.GainMargin,'abs',mUnits);
   YData = sprintf('%0.3g',YData);
   str{end+1,1} = getString(message('Controllib:plots:strDiskMarginLabel',DM));
   str{end+1,1} = getString(message('Controllib:plots:strGainMarginLabel', mUnits,YData));
   str{end+1,1} = getString(message('Controllib:plots:strAtFrequencyLabel', fUnits,FData));
else
   % Convert Phase Margin from deg to Axis Grid YUnits{2}
   pUnits = AxGrid.YUnits{2};
   YData = unitconv(info.Data.PhaseMargin,'deg',pUnits);
   YData = sprintf('%0.3g',YData);
   str{end+1,1} = getString(message('Controllib:plots:strDiskMarginLabel',DM));
   str{end+1,1} = getString(message('Controllib:plots:strPhaseMarginLabel',pUnits,YData));
   str{end+1,1} = getString(message('Controllib:plots:strAtFrequencyLabel',fUnits,FData));
end

if info.Data.DiskMargin>0
   Stable = getString(message('Controllib:plots:strYes'));
else
   Stable = getString(message('Controllib:plots:strNo'));
end
str{end+1,1} = getString(message('Controllib:plots:strClosedLoopStableLabel',Stable));