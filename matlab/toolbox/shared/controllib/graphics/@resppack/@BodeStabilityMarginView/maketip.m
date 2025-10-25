function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for BodeStabilityMarginView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 1986-2013 The MathWorks, Inc.

AxGrid = info.View.AxesGrid;
str = maketip_p(this,tip,info,AxGrid.XUnits,AxGrid.YUnits{:});
