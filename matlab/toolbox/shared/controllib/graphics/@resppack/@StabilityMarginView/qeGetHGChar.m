function info = qeGetHGChar(this)
% qeGetHGChar  Returns struct for testing
% info.Identifier = type of char
% info.HG = handles to hg objects

%  Copyright 1986-2006 The MathWorks, Inc.

info = struct(...
    'Identifier', {'Gain Margin';'Phase Margin'}, ...
    'HGLines', {reshape(this.MagPoints,1,1,length(this.MagPoints)); ...
    reshape(this.PhasePoints,1,1,length(this.PhasePoints))});