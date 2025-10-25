function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for SettleTimeView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2013 The MathWorks, Inc.


r = info.Carrier;
AxGrid = info.View.AxesGrid;

str{1,1} = getString(message('Controllib:plots:strResponseLabel',r.Name));

[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col); 
if any(AxGrid.Size(1:2)>1) || ShowFlag 
    % Show if MIMO or non trivial 
    str{end+1,1} = iotxt; 
end

str{end+1,1} = getString(message('Controllib:plots:strFinalValueLabel', ...
    sprintf('%0.3g', info.Data.FinalValue(info.Row,info.Col))));
