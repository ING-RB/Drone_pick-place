function FU = getValidFrequencyUnits(~)
% Returns list of valid frequency units.
%
%   FU = getValidFrequencyUnits() returns the list of frequency units
%   assignable to the FrequencyUnit property of FRD models.

%   Copyright 1986-2010 The MathWorks, Inc.

FU = {'rad/TimeUnit';'cycles/TimeUnit';'rad/s';'Hz';'kHz';'MHz';'GHz';'rpm'};
