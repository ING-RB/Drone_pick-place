function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for StepPeakRespView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2023 The MathWorks, Inc.

r = info.Carrier;
cData = info.Data;
AxGrid = info.View.AxesGrid;

str = {getString(message('Controllib:plots:strResponseLabel',r.Name))};
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col); 
if any(AxGrid.Size(1:2)>1) || ShowFlag 
   % Show if MIMO or non trivial 
   str = [str ; {iotxt}]; 
end
str = [str ; ...
   {getString(message('Controllib:plots:strPeakDeviationLabel', ...
   sprintf('%0.3g',cData.PeakResponse(info.Row,info.Col))))} ; ...
   {getString(message('Controllib:plots:strOvershootLabel', ...
   sprintf('%0.3g',cData.OverShoot(info.Row,info.Col))))}];

PeakTime = cData.Time(info.Row,info.Col)*tunitconv(cData.TimeUnits,AxGrid.XUnits);
pos = get(CursorInfo,'Position');
XDot = pos(1);  % dot position
if XDot==PeakTime
   % Peak is within focus
   str = [str ; {getString(message('Controllib:plots:strAtTimeLabel', ...
      AxGrid.XUnits, sprintf('%0.3g', XDot)))} ];
else
   % step(tf(1,[1 1])): PeakTime is typically a very large value that may
   % puzzle users.
   str = [str ; {getString(message('Controllib:plots:strAtTimeLabel', ...
      AxGrid.XUnits, sprintf('> %0.3g', XDot)))} ];
end
