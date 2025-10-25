function schema
%  SCHEMA  Defines properties for @UncertainTimeData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'UncertainTimeData', superclass);

% Public attributes
% np-by-nr-by-nc
schema.prop(c, 'Data', 'MATLAB array');      % XData
schema.prop(c, 'Bounds', 'MATLAB array');      % XData
% schema.prop(c, 'UpperAmplitudeBound', 'MATLAB array'); %YData
% schema.prop(c, 'LowerAmplitudeBound', 'MATLAB array'); %XData
schema.prop(c, 'Ts', 'MATLAB array'); %Sample Time
p = schema.prop(c, 'TimeUnits', 'string');
p.FactoryValue = 'seconds';


