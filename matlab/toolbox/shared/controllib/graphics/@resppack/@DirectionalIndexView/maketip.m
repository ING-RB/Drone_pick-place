function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for @RelSectorIndexView curves.

%   Copyright 2021 The MathWorks, Inc.
r = info.Carrier;
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
str = {getString(message('Controllib:plots:strResponseLabel',r.Name));...
      getString(message('Controllib:plots:strFrequencyLabel', ...
         AxGrid.XUnits,sprintf('%0.3g', Freq))); ...
      getString(message('Controllib:plots:strDirIndexLabel', ...
         AxGrid.YUnits,sprintf('%0.3g',pos(2))))}; 
