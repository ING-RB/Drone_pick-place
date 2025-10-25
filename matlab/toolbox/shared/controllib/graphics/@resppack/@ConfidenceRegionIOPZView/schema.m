function schema
%SCHEMA  Defines properties for @ConfidenceRegionIOPZView class

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('wrfc');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionIOPZView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'UncertainPoleCurves', 'MATLAB array');    % Handles of HG Lines (matrix)
schema.prop(c, 'UncertainZeroCurves', 'MATLAB array');    % Handles of HG Lines (matrix)

