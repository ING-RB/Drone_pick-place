function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for FreqPeakRespView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2013 The MathWorks, Inc.

r = info.Carrier;
cData = info.Data;
AxGrid = info.View.AxesGrid;
MagUnits = AxGrid.YUnits;
if iscell(MagUnits)
   MagUnits = MagUnits{1};  % for mag/phase plots
end

str{1,1} = getString(message('Controllib:plots:lblDataset',r.Name));
str{end+1,1} = localrcinfo(r,info.Row); 

% Note: Characteristic data expressed in same units as carrier's response data
XData = cData.Frequency{info.Row}*funitconv(cData.Parent.FreqUnits,AxGrid.XUnits);
YData = unitconv(cData.PeakGain{info.Row},cData.Parent.MagUnits,MagUnits);
str{end+1,1} = getString(message('Controllib:plots:strPeakAmplitudeLabel2', ...
    MagUnits,  sprintf('%0.3g',YData)));
str{end+1,1} = getString(message('Controllib:plots:strAtFrequencyLabel', ...
    AxGrid.XUnits,sprintf('%0.3g',XData)));

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
