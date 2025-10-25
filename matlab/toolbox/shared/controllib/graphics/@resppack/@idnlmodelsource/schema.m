function schema
%SCHEMA  Defines properties specific to @idnlmodelsource class.
% This class manages plots of nonlinear models of System Identification
% Toolbox.

%  Author(s): Rajiv Singh
%  Copyright 2010 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Register class 
c = schema.class(pkg, 'idnlmodelsource', findclass(pkg, 'respsource'));

% Class attributes
schema.prop(c, 'Model',    'MATLAB array');     % LTI model(s)
schema.prop(c, 'UncertainModel', 'MATLAB array');
% schema.prop(c, 'Cache', 'MATLAB array'); % Time resp. info (struct)
