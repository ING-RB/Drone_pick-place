function info = qeGetHGChar(this)
% qeGetHGChar  Returns struct for testing
% info.Identifier = type of char
% info.HGGroups = handles to hggroup objects

%  Copyright 2013 The MathWorks, Inc.
info = struct(...
    'Identifier', 'Mean Value', ...
    'HGGroups', this.Points);
 