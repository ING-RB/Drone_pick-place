function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for TimePeakRespView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2023 The MathWorks, Inc.
r = info.Carrier;
cData = info.Data;
AxGrid = info.View.AxesGrid;

str{1,1} =  getString(message('Controllib:plots:strResponseLabel',r.Name));
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str{end+1,1} = iotxt;
end

Peak = cData.PeakResponse(info.Row,info.Col);
str{end+1,1} = getString(message('Controllib:plots:strPeakAmplitudeLabel', ...
   sprintf('%0.3g',Peak)));

% Peak time display
PeakTime = cData.Time(info.Row,info.Col)*tunitconv(cData.TimeUnits,AxGrid.XUnits);
pos = get(CursorInfo,'Position');
XDot = pos(1);
if XDot==PeakTime
   % Peak is within focus
   str{end+1,1} = getString(message('Controllib:plots:strAtTimeLabel', ...
      AxGrid.XUnits, sprintf('%0.3g', XDot)));
else
   % impulse(tf(1,[1 1 0])): peak is reached beyond Xlim(2)
   str{end+1,1} = getString(message('Controllib:plots:strAtTimeLabel', ...
      AxGrid.XUnits, sprintf('> %0.3g', XDot)));
end
