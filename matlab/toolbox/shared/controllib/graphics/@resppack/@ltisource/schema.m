function schema
%SCHEMA  Defines properties specific to @ltisource class (LTI model)

%  Author(s): Bora Eryilmaz
%  Revised:   Kamesh Subbarao
%   Copyright 1986-2015 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Register class 
c = schema.class(pkg, 'ltisource', findclass(pkg, 'respsource'));

% Class attributes
p = schema.prop(c, 'Model',    'MATLAB array');     % LTI model(s)
p.SetFunction = {@localSetFunction, 'Model'};

schema.prop(c, 'PlotLTIData', 'MATLAB array');

schema.prop(c, 'UncertainModel', 'MATLAB array');

schema.prop(c, 'Cache', 'MATLAB array'); % Time resp. info (struct)
% Cache = struct array w/ fields Stable,MStable,DCGain,Margins

