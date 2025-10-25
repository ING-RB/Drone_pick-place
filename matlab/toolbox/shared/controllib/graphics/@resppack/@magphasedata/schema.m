function schema
%   SCHEMA  Defines properties for @freqdata class

%   Copyright 1986-2013 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wrfc'), 'data');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'magphasedata', supclass);

% Public attributes
schema.prop(c, 'Focus', 'MATLAB array');         % Focus (preferred frequency range)
schema.prop(c, 'Frequency', 'MATLAB array');     % Frequency vector, w
p = schema.prop(c, 'FreqUnits', 'string');       % Frequency units
p.FactoryValue = 'rad/s';
schema.prop(c, 'Magnitude', 'MATLAB array');     % Magnitude data
p = schema.prop(c, 'MagUnits', 'string');        % Magnitude units [{abs}|dB]
p.FactoryValue = 'abs';
schema.prop(c, 'Phase', 'MATLAB array');         % Phase data
p = schema.prop(c, 'PhaseUnits', 'string');      % Phase units [{rad}|deg]
p.FactoryValue = 'rad';
schema.prop(c, 'SoftFocus', 'bool');             % Soft vs hard focus bounds (default=0)
p = schema.prop(c, 'Ts', 'MATLAB array');        % Sample time (for Nyquist frequency)
p.FactoryValue = 0;
p = schema.prop(c, 'Real', 'bool');              % Real or complex system
p.FactoryValue = 1;
