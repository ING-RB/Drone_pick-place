function info = qeGetHGChar(this)
% qeGetHGChar  Returns struct for testing
% info.Identifier = type of char
% info.HG = handles to hg objects

%  Copyright 2021 The MathWorks, Inc.

info = struct(...
    'Identifier', 'Transient Time', ...
    'HGLines', this.Points);