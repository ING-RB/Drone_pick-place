function str = maketip(~,~,info,CursorInfo)
%MAKETIP  Build data tips for @bodeview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2013 The MathWorks, Inc.
r = info.Carrier;
AxGrid = info.View.AxesGrid;
pos = get(CursorInfo,'Position');
% Create tip text
str{1,1} = getString(message('Controllib:plots:lblDataset',r.Name));
str{end+1,1} = localrcinfo(r,info.Row);

str{end+1,1} = getString(message('Controllib:plots:strFrequencyLabel', ...
    AxGrid.XUnits,sprintf('%0.3g',pos(1))));
if info.SubPlot==1
   str{end+1,1} =  getString(message('Controllib:plots:strMagnitudeLabel',...
      AxGrid.YUnits{1},sprintf('%0.3g',pos(2))));
else
   str{end+1,1} = getString(message('Controllib:plots:strPhaseLabel',...
      AxGrid.YUnits{2},sprintf('%0.3g',pos(2))));
end

%-------------------------------------------------------------------------
function str = localrcinfo(r,Row)
%LOCALRCINFO  Constructs data tip text locating @iowave in axes grid.
%
%   The boolean SHOWNAME indicates that at least one of the names is 
%   user-defined (nonempty).

yNames = r.Parent.OutputName;
uNames = r.Parent.InputName;
ny = length(yNames);
if Row > ny
   uName = uNames{Row-ny};
   if isempty(uName)
      str = sprintf('Ch(%d)',r.InputIndex(Row-ny));
   else      
      str = uName;
   end
else
   yName = yNames{Row};
   if isempty(yName)
      str = sprintf('Ch(%d)',r.OutputIndex(Row));
   else 
      str = yName;
   end   
end
str =  getString(message('Controllib:plots:strChannelLabel',str));
