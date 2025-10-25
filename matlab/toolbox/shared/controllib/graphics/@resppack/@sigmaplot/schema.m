function schema
%SCHEMA  Defines properties for @sigmaplot class

%  Copyright 1986-2021 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('resppack');
c = schema.class(pkg, 'sigmaplot', findclass(pkg, 'respplot'));

% User-defined frequency focus (rad/s).
%   First row: linear scale 
%   Second row: log scale 
% Defaults to NaN(2) for "unspecified", set by BODE(SYS,W) or BODE(SYS,{WMIN,WMAX})
p = schema.prop(c, 'FreqFocus', 'MATLAB array');  
p.FactoryValue = NaN(2);

p = schema.prop(c,'UserSpecifiedFrequency','MATLAB array');

p = schema.prop(c,'FrequencyEditorDialog','MATLAB array');
p = schema.prop(c,'FrequencyEditorDialogCleanupListener','MATLAB array');