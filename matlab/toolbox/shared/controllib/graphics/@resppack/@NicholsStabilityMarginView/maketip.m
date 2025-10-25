function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for NicholsStabilityMarginView Characteristics.

%   Copyright 1986-2013 The MathWorks, Inc.

AxGrid = info.View.AxesGrid;
r = info.Carrier;
% UDDREVISIT
str = maketip_p(this,tip,info,r.Parent.FrequencyUnits,AxGrid.YUnits,AxGrid.XUnits);
