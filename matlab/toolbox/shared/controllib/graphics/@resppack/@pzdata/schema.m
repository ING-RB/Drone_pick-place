function schema
%   SCHEMA  Defines properties for @pzdata class

%   Author(s): Bora Eryilmaz
%   Revised:   Kamesh Subbarao, 10-29-2001
%   Copyright 1986-2010 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wrfc'), 'data');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'pzdata', supclass);

% Public attributes - Data
schema.prop(c, 'Poles',   'MATLAB array');       % Poles 
schema.prop(c, 'Zeros',   'MATLAB array');       % Zeros
schema.prop(c, 'Ts',      'MATLAB array');       % Sampling Time
p =schema.prop(c, 'TimeUnits', 'string');  % usings TimeUnits^(-1)
p.FactoryValue = 'seconds';