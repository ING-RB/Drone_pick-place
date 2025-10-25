function schema
%SCHEMA  Defines properties for @wavestyle class

%   Author(s): John Glass
%   Copyright 1986-2015 The MathWorks, Inc.

% Register class
c = schema.class(findpackage('wavepack'), 'wavestyle');

% Public attributes
schema.prop(c, 'Colors', 'MATLAB array'); 
p = schema.prop(c, 'SemanticColors', 'MATLAB array');
p = schema.prop(c, 'EnableTheming', 'MATLAB array');
p.FactoryValue = false;

schema.prop(c, 'LineStyles', 'MATLAB array');    
p = schema.prop(c, 'LineWidth', 'double');    
p.FactoryValue = 0.5;
schema.prop(c, 'Markers', 'MATLAB array');    
schema.prop(c, 'Legend', 'ustring'); 
schema.prop(c, 'GroupLegendInfo', 'MATLAB array');

% Event
schema.event(c,'StyleChanged');   % Notifies of change in style attributes