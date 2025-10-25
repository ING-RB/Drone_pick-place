function str = maketip(this,event_obj,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for @timeview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2013 The MathWorks, Inc.
r = info.Carrier;
AxGrid = info.View.AxesGrid;

pos = get(CursorInfo,'Position');
Y = pos(2);
X = pos(1);

k = info.Row;
ny = numel(info.Data.OutputData);
if k<=ny
   ts = info.Data.OutputData(k);
else
   ts = info.Data.InputData(k-ny);
end

if strcmp(AxGrid.YNormalization,'on')
   ax = ancestor(event_obj,'axes');
   Y = denormalize(info.Data,Y,get(ax,'XLim'),ts.Time,ts.Data);
end

I = [];
if size(ts.Data,2)>1
   I = localGetSubchannel(Y, ts.Data);
end

% Create tip text
str{1,1} = getString(message('Controllib:plots:lblDataset',r.Name));

[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial.
   if ~isempty(I)
      iotxt = sprintf('%s(:,%d)',iotxt, I);
   end
   str{end+1,1} = iotxt;
end
str{end+1,1} =  getString(message('Controllib:plots:strTimeLabel',...
   AxGrid.XUnits, sprintf('%0.3g',X)));
str{end+1,1} = getString(message('Controllib:plots:strAmplitudeLabel',...
   sprintf('%0.3g', Y)));

%--------------------------------------------------------------------------
function I = localGetSubchannel(x0, x)
% Colunm of x that (t0, x0) belongs to,

[Min, I] = min((x-x0).^2,[],1);
[~, J] = min(Min);
I = I(J);
