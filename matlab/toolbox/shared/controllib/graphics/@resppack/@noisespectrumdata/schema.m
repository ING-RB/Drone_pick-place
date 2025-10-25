function schema
% SCHEMA  Defines properties for @noisespectrumdata class.

% Copyright 2018 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('resppack'), 'magphasedata');

% Register class (subclass)

c = schema.class(findpackage('resppack'), 'noisespectrumdata', supclass);

schema.prop(c, 'Mean', 'MATLAB array');
schema.prop(c, 'Min', 'MATLAB array');
schema.prop(c, 'Max', 'MATLAB array');
schema.prop(c, 'SD', 'MATLAB array');
schema.prop(c, 'CommonFrequency', 'MATLAB array');

% For predmaint use
p = schema.prop(c, 'Context', 'MATLAB array');
