function clear(this)
%CLEAR  Clears data.

%  Author(s): Craig Buhr
%  Copyright 1986-2010 The MathWorks, Inc.

[this.Data.Frequency] = deal([]);
[this.Data.Magnitude] = deal([]);
[this.Data.Phase] = deal([]);

this.Bounds = struct(...
    'Frequency', [], ...
    'UpperMagnitudeBound', [], ...
    'LowerMagnitudeBound', [],...
    'UpperPhaseBound', [], ...
    'LowerPhaseBound', []);

this.Ts = [];