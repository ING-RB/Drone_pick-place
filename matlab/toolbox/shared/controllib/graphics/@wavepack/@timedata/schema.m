function schema
%  SCHEMA  Defines properties for @timedata class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2015 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wrfc'), 'data');

% Register class (subclass)
c = schema.class(findpackage('wavepack'), 'timedata', supclass);

% Public attributes
schema.prop(c, 'Focus', 'MATLAB array');         % Focus (preferred time range)
schema.prop(c, 'Amplitude',      'MATLAB array');   % Amplitude Y(t)
schema.prop(c, 'AmplitudeUnits', 'ustring');         % Amplitude units
schema.prop(c, 'Time',        'MATLAB array');      % Time vector, t
p = schema.prop(c, 'TimeUnits',   'string');        % Time units
p.FactoryValue = 'seconds';
schema.prop(c, 'Ts',   'double');                   % Sample time (for continuous vs. discrete)
