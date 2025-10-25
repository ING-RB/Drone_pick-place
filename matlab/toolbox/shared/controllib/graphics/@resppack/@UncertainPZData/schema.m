function schema
%  SCHEMA  Defines properties for @UncertainPZData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'UncertainPZData', superclass);


schema.prop(c, 'Data',   'MATLAB array');       % Poles 
schema.prop(c, 'Poles',   'MATLAB array');       % Poles 
schema.prop(c, 'Zeros',   'MATLAB array');       % Zeros
schema.prop(c, 'Ts',      'MATLAB array');       % Sampling Time
p =schema.prop(c, 'TimeUnits', 'string');  % usings TimeUnits^(-1)
p.FactoryValue = 'seconds';



