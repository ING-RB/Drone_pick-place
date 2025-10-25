function str = maketip(this,event_obj,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for @siminputviewPaired
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

AxGrid = info.View.AxesGrid;
pos = get(CursorInfo,'Position');

% Finalize Y data
Y = pos(2);
if strcmp(AxGrid.YNormalization,'on')
   ax = ancestor(event_obj,'axes');
   Y = denormalize(info.Data,Y,get(ax,'XLim'));
end
   
% Create tip text
% InputIndex = info.ArrayIndex;
iName = info.Carrier.ChannelName{info.Row};
if isempty(iName)
   iName = getString(message('Controllib:plots:strInputLabel', ...
   getString(message('Controllib:plots:strInIndex',info.Row))));
else
   iName = getString(message('Controllib:plots:strInputLabel',iName));
end
str = {iName ; ...
      getString(message('Controllib:plots:strTimeLabel', AxGrid.XUnits,  ...
           sprintf('%0.3g', pos(1)))) ;...
      getString(message('Controllib:plots:strAmplitudeLabel',sprintf('%0.3g', Y)))};
