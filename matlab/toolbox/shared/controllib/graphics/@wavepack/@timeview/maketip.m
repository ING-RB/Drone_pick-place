function str = maketip(this,event_obj,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for @timeview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2014 The MathWorks, Inc.

r = info.Carrier;
AxGrid = info.View.AxesGrid;

pos = get(CursorInfo,'Position');
Y = pos(2);
X = pos(1);

if strcmp(AxGrid.YNormalization,'on')
    ax = ancestor(event_obj,'axes');
    Y = denormalize(info.Data,Y,get(ax,'XLim'),info.Row,info.Col);
end
   
% Create tip text
str{1,1} = getString(message('Controllib:plots:strResponseLabel',r.Name));
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str{end+1,1} = iotxt;
end
str{end+1,1} =  getString(message('Controllib:plots:strTimeLabel',...
    AxGrid.XUnits, sprintf('%0.3g',X)));
str{end+1,1} = getString(message('Controllib:plots:strAmplitudeLabel',...
    sprintf('%0.3g', Y)));

