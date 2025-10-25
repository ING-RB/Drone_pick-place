function info = qeGetHGChar(this)
% qeGetHGChar  Returns struct for testing
% info.Identifier = type of char
% info.HG = handles to hg objects

%  Copyright 1986-2006 The MathWorks, Inc.


% make MagPoints and PhasePoints have coordinants corresponding to axes
MagPoints = [reshape(this.MagPoints,1,1,length(this.MagPoints)); ...
     repmat(wrfc.createDefaultHandle,[1,1, length(this.MagPoints)])];

PhasePoints = [repmat(wrfc.createDefaultHandle,[1,1, length(this.PhasePoints)]); ...
    reshape(this.PhasePoints,1,1,length(this.PhasePoints))];
    

info = struct(...
    'Identifier', {'Gain Margin';'Phase Margin'}, ...
    'HGLines', {MagPoints; PhasePoints});