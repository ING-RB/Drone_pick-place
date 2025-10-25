function schema
%SCHEMA  Defines properties specific to @ltisource class (LTI model)

%   Copyright 2022 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Register class 
c = schema.class(pkg, 'ltvsource', findclass(pkg, 'respsource'));

% Class attributes
schema.prop(c, 'Model',    'MATLAB array');     % LTI model(s)

