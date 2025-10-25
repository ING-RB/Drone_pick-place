function schema
%SCHEMA  Defines properties for @DirectionalIndexWorstData class

%  Copyright 1986-2021 The MathWorks, Inc.

% Register class (subclass)
supclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'DirectionalIndexWorstData', supclass);
schema.prop(c, 'Frequency', 'MATLAB array'); % Frequency where index is minimum
schema.prop(c, 'MinIndex', 'MATLAB array');  % Minimum (worst) index
