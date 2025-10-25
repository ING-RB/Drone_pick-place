function str = maketip(this,tip,info,~) %#ok<INUSL>
%MAKETIP  Build data tips for SettleTimeView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2021 The MathWorks, Inc.
r = info.Carrier;
AxGrid = info.View.AxesGrid;

str = {getString(message('Controllib:plots:strResponseLabel',r.Name))};
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col); 
if any(AxGrid.Size(1:2)>1) || ShowFlag 
    % Show if MIMO or non trivial 
    str{end+1,1} = iotxt; 
end

TransientTime = info.Data.Time(info.Row,info.Col);
% For step/impulse, transient time is measured relative to step/impulse time
if strcmp(r.Context.Type,'initial')
   Delay = 0;
else
   Delay = r.Context.Config.Delay;
end
if isfinite(TransientTime)
   str{end+1,1} = getString(message('Controllib:plots:strTransientTimeLabel',...
      AxGrid.XUnits,sprintf('%0.3g',(TransientTime-Delay)*...
      tunitconv(info.Data.TimeUnits,AxGrid.XUnits))));
else
   % Unstable model
   str{end+1,1} = getString(message('Controllib:plots:strTransientTimeLabel',...
      AxGrid.XUnits,getString(message('Controllib:plots:strNone'))));
end
