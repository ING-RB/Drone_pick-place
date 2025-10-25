function clear(this)
%CLEAR  Clears data.

%  Author(s): Craig Buhr
%  Copyright 1986-2010 The MathWorks, Inc.

[this.Data.Time] = deal([]);
[this.Data.Amplitude] = deal([]);

this.Bounds = struct(...
    'Time', [], ...
    'UpperAmplitudeBound', [], ...
    'LowerAmplitudeBound', []);

this.Ts = [];