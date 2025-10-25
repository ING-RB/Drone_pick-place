function schema
%SCHEMA  Defines properties for @StepRiseTimeView class

%   Author(s): John Glass
%   Copyright 1986-2004 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wrfc'), 'PointCharView');
c = schema.class(findpackage('resppack'), 'StepRiseTimeView', superclass);

% Public attributes
schema.prop(c, 'HLines', 'MATLAB array');    % Handles of horizontal lines 
schema.prop(c, 'UpperVLines', 'MATLAB array');    % Handles of vertical lines 
schema.prop(c, 'LowerVLines', 'MATLAB array');    % Handles of vertical lines 