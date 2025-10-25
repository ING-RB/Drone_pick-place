function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for TimePeakRespView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2013-2015 The MathWorks, Inc.

r = info.Carrier;
cData = info.Data;
AxGrid = info.View.AxesGrid;

str{1,1} =  getString(message('Controllib:plots:lblDataset',r.Name));
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str{end+1,1} = iotxt;
end

Mean = cData.Mean{info.Row,info.Col};
if ~isscalar(Mean)
   pos = get(CursorInfo,'Position');
   Y = pos(2);
   [~, I] = min(abs(Mean-Y));
   Mean = Mean(I);
end

str{end+1,1} = getString(message('Controllib:plots:lblMean', ...
   sprintf('%0.3g',Mean)));

