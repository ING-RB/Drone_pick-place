function schema
%SCHEMA  Defines properties for @pzdata class

%   Copyright 1986-2020 The MathWorks, Inc.
supclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'hsvdata', supclass);

% Public attributes - Data
schema.prop(c, 'HSV',   'MATLAB array');
schema.prop(c, 'ErrorBound',   'MATLAB array');
schema.prop(c, 'ErrorType',   'MATLAB array');