function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for FreqPeakRespView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2013 The MathWorks, Inc.

r = info.Carrier;
cData = info.Data;
AxGrid = info.View.AxesGrid;
MagUnits = AxGrid.YUnits;
if iscell(MagUnits)
   MagUnits = MagUnits{1};  % for mag/phase plots
end

str{1,1} = getString(message('Controllib:plots:strResponseLabel',r.Name));
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col); 
if any(AxGrid.Size(1:2)>1) || ShowFlag 
    % Show if MIMO or non trivial 
    str{end+1,1} = iotxt; 
end

% Note: Characteristic data expressed in same units as carrier's response data
XData = cData.Frequency(info.Row,info.Col)*funitconv(cData.Parent.FreqUnits,AxGrid.XUnits);
YData = unitconv(cData.PeakGain(info.Row,info.Col),cData.Parent.MagUnits,MagUnits);
str{end+1,1} = getString(message('Controllib:plots:strPeakGainLabel', ...
    MagUnits,  sprintf('%0.3g',YData)));
str{end+1,1} = getString(message('Controllib:plots:strAtFrequencyLabel', ...
    AxGrid.XUnits,sprintf('%0.3g',XData)));
