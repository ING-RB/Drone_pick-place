function schema
%  SCHEMA  Defines properties for @StepRiseTimeData class

%  Author(s): John Glass
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'StepRiseTimeData', superclass);

% Public attributes
schema.prop(c, 'TLow', 'MATLAB array');      % XData
schema.prop(c, 'THigh', 'MATLAB array');     % XData
schema.prop(c, 'Amplitude', 'MATLAB array'); % YData
p = schema.prop(c, 'TimeUnits',   'string');        % Time units
p.FactoryValue = 'seconds';

% Preferences
p = schema.prop(c, 'RiseTimeLimits', 'MATLAB array');
p.FactoryValue = [0.1 0.9];
