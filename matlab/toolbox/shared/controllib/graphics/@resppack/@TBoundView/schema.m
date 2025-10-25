function schema
%SCHEMA  Defines properties for @TBoundView class.

%  Copyright 1986-2013 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'TBoundView', superclass);

% Class attributes
schema.prop(c, 'Patch', 'MATLAB array'); % Bound patch

p = schema.prop(c, 'ZLevel', 'MATLAB array');     % ZLevel
p.FactoryValue = -2;
