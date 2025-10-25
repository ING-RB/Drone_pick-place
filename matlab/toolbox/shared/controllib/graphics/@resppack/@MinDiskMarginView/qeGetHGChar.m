function info = qeGetHGChar(this)
% qeGetHGChar  Returns struct for testing
% info.Identifier = type of char
% info.HG = handles to hg objects

%  Copyright 1986-2006 The MathWorks, Inc.

% make MagPoints and PhasePoints have coordinants corresponding to axes
MagPoints = [this.MagPoints;wrfc.createDefaultHandle];
PhasePoints = [wrfc.createDefaultHandle;this.PhasePoints];
info = struct(...
    'Identifier', {'Gain Margin';'Phase Margin'}, ...
    'HGLines', {MagPoints; PhasePoints});