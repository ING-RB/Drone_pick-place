function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for NyquistStabilityMarginView Characteristics.

%   Author(s): John Glass
%   Copyright 1986-2013 The MathWorks, Inc.

h = info.Carrier.Parent; % plot handle
% UDDREVISIT
str = maketip_p(this,tip,info,h.FrequencyUnits,h.MagnitudeUnits,h.PhaseUnits);
