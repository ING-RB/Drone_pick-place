function schema
% SCHEMA Class definition for @SpectrumView 

% Author(s): Erman Korkut 12-Mar-2009
% Revised:
% Copyright 1986-2009 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');
% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(pkg, 'spectrumview', superclass);

% Class attributes
schema.prop(c, 'Curves', 'MATLAB array');  % Handles of HG lines (matrix)
p = schema.prop(c, 'Style', 'string');     % Discrete time system curve style [stairs|stem]
p.FactoryValue = 'stairs';