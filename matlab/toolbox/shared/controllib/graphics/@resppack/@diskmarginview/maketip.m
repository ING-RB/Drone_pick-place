function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for @SigmaMarginView curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 1986-2014 The MathWorks, Inc.
r = info.Carrier; % Waveform
AxGrid = info.View.AxesGrid;
pos = get(CursorInfo,'Position');

% Frequency
if strcmp(AxGrid.XScale{1},'log')
   idx = CursorInfo.DataIndex;
   if this.Frequency(idx)>0
      Freq = pos(1);
   else
      Freq = -pos(1);
   end
else
   Freq = pos(1);
end

% Create tip text
str = {
   getString(message('Controllib:plots:strResponseLabel',r.Name));
   getString(message('Controllib:plots:strFrequencyLabel', ...
   controllibutils.utXlateUnitsString(AxGrid.XUnits),sprintf('%0.3g', Freq)))};
if info.SubPlot==1
   str{end+1,1} =  getString(message('Controllib:plots:strDiskMarginTip1',...
      controllibutils.utXlateUnitsString(AxGrid.YUnits{1}),sprintf('%0.3g',pos(2))));
else
   str{end+1,1} =  getString(message('Controllib:plots:strDiskMarginTip2',...
      controllibutils.utXlateUnitsString(AxGrid.YUnits{2}),sprintf('%0.3g',pos(2))));
end