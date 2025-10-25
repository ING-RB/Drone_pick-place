function schema
%SCHEMA  Defines properties for @StepRiseTimeView class

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('wrfc');
c = schema.class(findpackage('resppack'), 'UncertainTimeView', findclass(pkg,'view'));

% Public attributes
schema.prop(c, 'UncertainPatch', 'MATLAB array');    % Handles of Patch 
schema.prop(c, 'UncertainLines', 'MATLAB array');    % Handles of Lines
p = schema.prop(c, 'UncertainType', 'MATLAB array');    % Uncertain Type: Bounds, Systems
p.FactoryValue = 'Systems';
