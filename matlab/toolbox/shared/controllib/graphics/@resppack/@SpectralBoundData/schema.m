function schema
% SCHEMA

%  Author(s): Craig Buhr
%   Copyright 1986-2012 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'SpectralBoundData', superclass);

% Public attributes
schema.prop(c, 'MinDecay', 'MATLAB array'); 
schema.prop(c, 'MinDamping', 'MATLAB array'); 
schema.prop(c, 'MaxFrequency', 'MATLAB array'); 
p = schema.prop(c, 'Ts', 'MATLAB array'); 
p.FactoryValue = 0;
p = schema.prop(c, 'TimeUnits', 'string'); 
p.FactoryValue = 'seconds';




