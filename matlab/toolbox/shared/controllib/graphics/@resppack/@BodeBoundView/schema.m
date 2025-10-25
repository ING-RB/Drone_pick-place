function schema
% Class definition.

%  Copyright 1986-2014 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'BodeBoundView', superclass);

% Class attributes
schema.prop(c, 'MagPatch', 'MATLAB array');
schema.prop(c, 'PhasePatch', 'MATLAB array');

p = schema.prop(c, 'BoundType', 'MATLAB array');     % "upper" or "lower"
p.FactoryValue = 'upper';

p = schema.prop(c, 'ZLevel', 'MATLAB array');     % ZLevel
p.FactoryValue = -2;