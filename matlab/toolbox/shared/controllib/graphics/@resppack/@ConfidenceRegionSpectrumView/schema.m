function schema
%SCHEMA  Defines properties for @ConfidenceRegionSpectrumView class

%   Author(s): Craig Buhr
%   Copyright 1986-2011 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('wrfc');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionSpectrumView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'UncertainMagPatch', 'MATLAB array');    % Handles of Patch
schema.prop(c, 'UncertainMagLines', 'MATLAB array');    % Handles of Lines
p = schema.prop(c, 'UncertainType', 'MATLAB array');    % Uncertain Type: Bounds, Systems
p.FactoryValue = 'Bounds';
