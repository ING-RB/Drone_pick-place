function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for @bodeview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 1986-2021 The MathWorks, Inc.

r = info.Carrier;
AxGrid = info.View.AxesGrid;
pos = get(CursorInfo,'Position');
% Create tip text
str = {getString(message('Controllib:plots:strResponseLabel',r.Name))};
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str = [str ; {iotxt}];
end
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
str1 = getString(message('Controllib:plots:strFrequencyLabel', ...
    AxGrid.XUnits,sprintf('%0.3g',Freq)));
% Mag or phase
if info.SubPlot==1
   str2 =  getString(message('Controllib:plots:strMagnitudeLabel',...
      AxGrid.YUnits{1},sprintf('%0.3g',pos(2))));
else
   str2 = getString(message('Controllib:plots:strPhaseLabel',...
      AxGrid.YUnits{2},sprintf('%0.3g',pos(2))));
end
str = [str ; {str1;str2}];