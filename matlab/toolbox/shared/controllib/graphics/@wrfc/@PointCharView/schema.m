function schema
%SCHEMA  Class definition for @PointCharView (dot-marked characteristics) 

%   Copyright 1986-2004 The MathWorks, Inc.

% Register class (subclass of wfrc/view)
pkg = findpackage('wrfc');
c = schema.class(pkg, 'PointCharView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'Points', 'MATLAB array');     % Handles of dot markers
schema.prop(c, 'PointTips', 'MATLAB array');  % Handles of marker tips (cell array)