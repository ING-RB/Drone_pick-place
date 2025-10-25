function schema
%SCHEMA  Defines properties for @StepSteadyStateView class

%   Author(s): John Glass
%   Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'PointCharView');
c = schema.class(findpackage('resppack'), 'StepSteadyStateView', superclass);
