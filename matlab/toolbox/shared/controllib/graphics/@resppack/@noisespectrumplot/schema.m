function schema
%  SCHEMA  Defines properties for @noisespectrumplot class

%  Author(s): Rajiv Singh
%  Copyright 2011-2018 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Find parent class (superclass)
supclass = findclass(pkg, 'respplot');

% Register class (subclass)
c = schema.class(pkg, 'noisespectrumplot', supclass);

% User-defined frequency focus (rad/s).
%   First row: linear scale 
%   Second row: log scale 
% Defaults to NaN(2) for "unspecified", set by BODE(SYS,W) or BODE(SYS,{WMIN,WMAX})
p = schema.prop(c, 'FreqFocus', 'MATLAB array');  
p.FactoryValue = NaN(2);

% For predmaint use
schema.prop(c, 'Context', 'MATLAB array');

p = schema.prop(c, 'ConfidenceRegionContainer', 'MATLAB array'); 