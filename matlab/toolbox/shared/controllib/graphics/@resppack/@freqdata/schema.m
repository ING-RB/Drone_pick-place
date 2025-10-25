function schema
%   SCHEMA  Defines properties for @freqdata class

%   Author(s): P. Gahinet
%   Copyright 1986-2010 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wrfc'), 'data');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'freqdata', supclass);

% Public attributes
schema.prop(c, 'Focus', 'MATLAB array');         % Focus (preferred frequency range)
schema.prop(c, 'Frequency', 'MATLAB array');     % Frequency vector
p = schema.prop(c, 'FreqUnits', 'string');       % Frequency units
p.FactoryValue = 'rad/s';
schema.prop(c, 'Response', 'MATLAB array');      % Frequency response data
schema.prop(c, 'SoftFocus', 'bool');             % Soft vs hard focus bounds (default=0)
schema.prop(c, 'Ts', 'double');                  % Sample time (for Nyquist frequency)
schema.prop(c, 'Real', 'bool');                  % Real or complex system