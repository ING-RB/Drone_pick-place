function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for SettleTimeView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2013 The MathWorks, Inc.

r = info.Carrier;
AxGrid = info.View.AxesGrid;

str = {getString(message('Controllib:plots:strResponseLabel',r.Name))};
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col); 
if any(AxGrid.Size(1:2)>1) || ShowFlag 
    % Show if MIMO or non trivial 
    str{end+1,1} = iotxt; 
end

Time = info.Data.Time(info.Row,info.Col);
StepDelay = r.Context.Config.Delay;
if isinf(Time)
   % Unstable model
   str{end+1,1} = getString(message('Controllib:plots:strSettlingTimeLabel',...
       AxGrid.XUnits,getString(message('Controllib:plots:strNone'))));
else
   str{end+1,1} = getString(message('Controllib:plots:strSettlingTimeLabel',...
        AxGrid.XUnits,sprintf('%0.3g',(Time-StepDelay)*...
        tunitconv(info.Data.TimeUnits,AxGrid.XUnits))));
end
