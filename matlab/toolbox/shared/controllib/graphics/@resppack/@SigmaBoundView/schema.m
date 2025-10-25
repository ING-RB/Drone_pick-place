function schema
%SCHEMA  Defines properties for @sigmaview class.

%  Author(s): Kamesh Subbarao
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'SigmaBoundView', superclass);

% Class attributes
schema.prop(c, 'Curves', 'MATLAB array');        % Handles of sv curves

p = schema.prop(c, 'BoundType', 'MATLAB array');     % "upper" or "lower"
p.FactoryValue = 'upper';

p = schema.prop(c, 'ZLevel', 'MATLAB array');     % ZLevel
p.FactoryValue = -2;
