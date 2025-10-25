function schema
%SCHEMA  Defines properties for @SBoundView class.

%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'SBoundView', superclass);

% Class attributes
schema.prop(c, 'Patch', 'MATLAB array'); % Bound patch

p = schema.prop(c, 'ZLevel', 'MATLAB array');     % ZLevel
p.FactoryValue = -2;
