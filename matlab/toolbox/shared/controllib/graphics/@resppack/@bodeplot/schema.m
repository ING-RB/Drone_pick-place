function schema
%  SCHEMA  Defines properties for @bodeplot class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2021 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Find parent class (superclass)
supclass = findclass(pkg, 'respplot');

% Register class (subclass)
c = schema.class(pkg, 'bodeplot', supclass);

% Public properties
p(1) = schema.prop(c, 'MagVisible',   'on/off');  % Visibility of mag plot
p(2) = schema.prop(c, 'PhaseVisible', 'on/off');  % Visibility of phase plot
set(p, 'FactoryValue', 'on')

% User-defined frequency focus (rad/s).
%   First row: linear scale 
%   Second row: log scale 
% Defaults to NaN(2) for "unspecified", set by BODE(SYS,W) or BODE(SYS,{WMIN,WMAX})
p = schema.prop(c, 'FreqFocus', 'MATLAB array');  
p.FactoryValue = NaN(2);

p = schema.prop(c, 'MagnitudeResponseContainer', 'MATLAB array');
p = schema.prop(c, 'PhaseResponseContainer', 'MATLAB array');
p = schema.prop(c, 'ConfidenceRegionContainer', 'MATLAB array');

p = schema.prop(c,'UserSpecifiedFrequency','MATLAB array');

p = schema.prop(c,'FrequencyEditorDialog','MATLAB array');
p = schema.prop(c,'FrequencyEditorDialogCleanupListener','MATLAB array');
