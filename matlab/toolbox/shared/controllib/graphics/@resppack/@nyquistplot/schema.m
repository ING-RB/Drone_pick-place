function schema
%  SCHEMA  Defines properties for @nyquistplot class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2010 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Find parent class (superclass)
supclass = findclass(pkg, 'respplot');

% Register class (subclass)
c = schema.class(pkg, 'nyquistplot', supclass);

% Properties
p = schema.prop(c, 'FrequencyUnits', 'string');  % Frequency units
p.FactoryValue = 'rad/s';
p = schema.prop(c, 'ShowFullContour', 'on/off'); % 'on' -> show branch for w<0
p.FactoryValue = 'on';
p = schema.prop(c,'MagnitudeUnits','string');  % Magnitude units for peak response characteristic
p.FactoryValue = 'dB';
p = schema.prop(c,'PhaseUnits','string');  % Phase units for phase margin characteristic
p.FactoryValue = 'deg';

p = schema.prop(c, 'ConfidenceRegionContainer', 'MATLAB array'); 

p = schema.prop(c,'UserSpecifiedFrequency','MATLAB array');

p = schema.prop(c,'FrequencyEditorDialog','MATLAB array');
p = schema.prop(c,'FrequencyEditorDialogCleanupListener','MATLAB array');