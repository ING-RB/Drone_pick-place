function schema
%SCHEMA  Defines properties for @ConfidenceRegionNyquistView class

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('wrfc');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionNyquistView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'UncertainNyquistCurves', 'MATLAB array');    % Handles of HG Lines (matrix)
schema.prop(c, 'UncertainNyquistNegCurves', 'MATLAB array');    % Handles of HG Lines (matrix)

schema.prop(c, 'UncertainNyquistMarkers', 'MATLAB array');    % Handles of HG Lines (matrix)
schema.prop(c, 'UncertainNyquistNegMarkers', 'MATLAB array');    % Handles of HG Lines (matrix)




