function str = maketip(this,tip,info,CursorInfo)  %#ok<INUSD,INUSL>
%MAKETIP  Build data tips for RelativeIndexPeakRespView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2021 The MathWorks, Inc.
r = info.Carrier;
cData = info.Data;
AxGrid = info.View.AxesGrid;

str1 = getString(message('Controllib:plots:strResponseLabel',r.Name));

% Note: Characteristic data expressed in same units as carrier's response data
XData = cData.Frequency*funitconv(cData.Parent.FreqUnits,AxGrid.XUnits);
YData = cData.MinIndex;
str2 = getString(message('Controllib:plots:strMinIndexLabel', ...
    cData.Parent.IndexUnits,  sprintf('%0.3g',YData)));
str3 = getString(message('Controllib:plots:strAtFrequencyLabel', ...
    AxGrid.XUnits,sprintf('%0.3g',XData)));
str = {str1;str2;str3};