function schema
%  SCHEMA  Defines properties for @pzplot class

%  Author(s): Bora Eryilmaz
%  Revised:   Kamesh Subbarao, 10-29-2001
%  Copyright 1986-2010 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Find parent class (superclass)
supclass = findclass(pkg, 'respplot');

% Register class (subclass)
c = schema.class(pkg, 'pzplot', supclass);

% Properties
p = schema.prop(c, 'FrequencyUnits', 'string');  % Frequency units
p.FactoryValue = 'rad/s';


p = schema.prop(c, 'TimeUnits', 'string');  % Time units
p.FactoryValue = 'seconds';

p = schema.prop(c, 'ConfidenceRegionContainer', 'MATLAB array'); 