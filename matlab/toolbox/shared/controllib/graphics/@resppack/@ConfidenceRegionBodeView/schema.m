function schema
%SCHEMA  Defines properties for @ConfidenceRegionBodeView class

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('wrfc');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionBodeView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'UncertainMagPatch', 'MATLAB array');    % Handles of Patch
schema.prop(c, 'UncertainPhasePatch', 'MATLAB array');    % Handles of Patch 
schema.prop(c, 'UncertainMagLines', 'MATLAB array');    % Handles of Lines
schema.prop(c, 'UncertainPhaseLines', 'MATLAB array');    % Handles of Lines
p = schema.prop(c, 'UncertainType', 'MATLAB array');    % Uncertain Type: Bounds, Systems
p.FactoryValue = 'Bounds';
