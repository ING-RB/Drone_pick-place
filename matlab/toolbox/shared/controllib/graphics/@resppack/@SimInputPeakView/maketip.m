function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for SimInputPeakView Characteristics.

%   Copyright 1986-2013 The MathWorks, Inc.

AxGrid = info.View.AxesGrid;
InputIndex = info.ArrayIndex;
iName = info.Carrier.ChannelName{InputIndex};
if isempty(iName)
    iName = getString(message('Controllib:plots:strInputLabel', ...
        getString(message('Controllib:plots:strInIndex',InputIndex))));
else
   iName = getString(message('Controllib:plots:strInputLabel',iName));
end
str = {iName ; ...
       getString(message('Controllib:plots:strPeakAmplitudeLabel', ...
           sprintf('%0.3g',info.Data.PeakResponse(1)))) ;...
       getString(message('Controllib:plots:strAtTimeLabel', ...
           AxGrid.XUnits, ...
           sprintf('%0.3g', info.Data.Time(1)*tunitconv(info.Data.TimeUnits, AxGrid.XUnits))))};
