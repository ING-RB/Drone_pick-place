function schema
%  SCHEMA  Defines properties for @TimeFinalValueData class

%  Author(s): John Glass
%  Revised:
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'TimeFinalValueData', superclass);

% Public attributes
schema.prop(c, 'FinalValue', 'MATLAB array'); % FinalValue
