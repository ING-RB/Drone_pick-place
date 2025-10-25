function info = qeGetHGChar(this)
% qeGetHGChar  Returns struct for testing
% info.Identifier = type of char
% info.HG = handles to hg objects

%  Copyright 1986-2006 The MathWorks, Inc.

info = struct(...
    'Identifier', 'Settling Time', ...
    'HGLines', this.Points);