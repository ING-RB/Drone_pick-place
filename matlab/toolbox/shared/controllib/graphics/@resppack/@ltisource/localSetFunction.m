function sys = localSetFunction(this, sys, ~)
% Note: UDD/LXE issue prevents using local function

% Copyright 2015-2022 The MathWorks, Inc.

% Note: GETVALUE samples uncertainty and returns LTI or IDLTI.
sys = getValue(sys,'usample');
this.PlotLTIData = getPlotLTIData(sys);