function schema
%SCHEMA  Defines properties specific to @SigmaBoundSource class (LTI model)

%   Copyright 1986-2016 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Register class 
c = schema.class(pkg, 'SigmaBoundSource', findclass(pkg, 'respsource'));

% Class attributes
schema.prop(c, 'Model',    'MATLAB array');    % LTI model(s)
schema.prop(c, 'Focus',    'MATLAB array');   % frequency

p = schema.prop(c, 'UseFocus',    'MATLAB array');   % Use computed XLimFocus
p.FactoryValue = true;