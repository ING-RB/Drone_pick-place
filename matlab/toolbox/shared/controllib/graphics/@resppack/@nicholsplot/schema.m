function schema
%  SCHEMA  Defines properties for @nicholsplot class

%  Author(s): Bora Eryilmaz
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Find parent class (superclass)
supclass = findclass(pkg, 'respplot');

% Register class (subclass)
c = schema.class(pkg, 'nicholsplot', supclass);

% Properties
p = schema.prop(c, 'FrequencyUnits', 'string');  % Frequency units
p.FactoryValue = 'rad/s';

p = schema.prop(c, 'MagnitudeResponseContainer', 'MATLAB array');
p = schema.prop(c, 'PhaseResponseContainer', 'MATLAB array');

p = schema.prop(c,'UserSpecifiedFrequency','MATLAB array');

p = schema.prop(c,'FrequencyEditorDialog','MATLAB array');
p = schema.prop(c,'FrequencyEditorDialogCleanupListener','MATLAB array');