function schema
%SCHEMA  Defines properties for @TimeFinalValueView class

%   Author(s): John Glass
%   Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'TimeFinalValueView', superclass);

% Public attributes
schema.prop(c, 'HLines', 'MATLAB array');    % Handles of horizontal lines 