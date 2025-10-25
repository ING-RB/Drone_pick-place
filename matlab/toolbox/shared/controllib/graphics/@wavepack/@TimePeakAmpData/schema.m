function schema
%SCHEMA  Defines properties for @TimePeakAmpData class

%  Author(s): John Glass
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('wavepack'), 'TimePeakAmpData', superclass);

% Public attributes
schema.prop(c, 'Time', 'MATLAB array');         % Time where amplitude peaks
schema.prop(c, 'PeakResponse', 'MATLAB array'); % Amplitude at peak

p = schema.prop(c, 'TimeUnits',   'string');        % Time units
p.FactoryValue = 'seconds';
