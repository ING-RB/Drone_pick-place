function schema
%SCHEMA  Defines properties for @ConfidenceRegionTimeView class

%   Author(s): Craig Buhr
%   Copyright 1986-2011 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('wrfc');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionTimeView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'UncertainPatch', 'MATLAB array');    % Handles of Patch 
schema.prop(c, 'UncertainLines', 'MATLAB array');    % Handles of Lines
p = schema.prop(c, 'UncertainType', 'MATLAB array'); % Uncertain Type: Bounds, Systems
p.FactoryValue = 'Bounds';
