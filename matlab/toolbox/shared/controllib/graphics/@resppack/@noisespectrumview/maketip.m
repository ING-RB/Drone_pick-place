function str = maketip(~,tip,info,CursorInfo)
%MAKETIP  Build data tips for @bodeview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): P. Gahinet
%   Copyright 1986-2013 The MathWorks, Inc.

r = info.Carrier;
AxGrid = info.View.AxesGrid;
pos = get(CursorInfo,'Position');

% Create tip text
str{1,1} = getString(message('Controllib:plots:strResponseLabel',r.Name));
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str{end+1,1} = iotxt;
end
str{end+1,1} = getString(message('Controllib:plots:strFrequencyLabel', ...
   AxGrid.XUnits,sprintf('%0.3g',pos(1))));

str{end+1,1} =  getString(message('Controllib:plots:strMagnitudeLabel',...
   AxGrid.YUnits,sprintf('%0.3g',pos(2))));
