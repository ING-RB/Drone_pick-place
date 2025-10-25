function schema
%   SCHEMA  Defines properties for @DirectionalIndexData class

%   Copyright 2015-2021 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wrfc'), 'data');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'DirectionalIndexData', supclass);

% Public attributes
schema.prop(c, 'Frequency', 'MATLAB array');     % Frequency vector
p = schema.prop(c, 'FreqUnits', 'string');       % Frequency units
p.FactoryValue = 'rad/s';
schema.prop(c, 'Index', 'MATLAB array');         % Index data
p = schema.prop(c, 'IndexUnits', 'string');      % For data tip
p.FactoryValue = 'abs';
p = schema.prop(c, 'Ts', 'MATLAB array');        % Sample time (for Nyquist frequency)
p.FactoryValue = 0;
schema.prop(c, 'Real', 'bool');                  % Real or complex system

schema.prop(c, 'Focus', 'MATLAB array');         % Focus (preferred frequency range)
schema.prop(c, 'SoftFocus', 'bool');             % Soft vs hard focus bounds (default=0)

