function schema
%SCHEMA  Defines properties for @timeview class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2015 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'timeview', superclass);

% Class attributes
p = schema.prop(c, 'Curves', 'MATLAB array');  % Handles of HG lines (matrix)

p = schema.prop(c, 'Style', 'string');     % Discrete time system curve style [stairs|stem]
p.FactoryValue = 'stairs';
p.setfunction = {@localSetFunction, 'Style',};

p = schema.prop(c, 'StemLines', 'MATLAB array'); 
p.AccessFlags.PublicSet = 'off';




