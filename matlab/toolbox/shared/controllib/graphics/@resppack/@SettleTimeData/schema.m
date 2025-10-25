function schema
%  SCHEMA  Defines properties for @SettleTimeData class

%  Author(s): John Glass
%  Revised:
%   Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'SettleTimeData', superclass);

% Public attributes
schema.prop(c, 'Time',    'MATLAB array'); % XData
schema.prop(c, 'YSettle', 'MATLAB array'); % YData
schema.prop(c, 'FinalValue',  'MATLAB array'); % Final value

p = schema.prop(c, 'TimeUnits',   'string');        % Time units
p.FactoryValue = 'seconds';

% Preferences
p = schema.prop(c, 'SettlingTimeThreshold', 'MATLAB array');
p.FactoryValue = 0.02;
