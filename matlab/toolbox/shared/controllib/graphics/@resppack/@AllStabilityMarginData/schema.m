function schema
%  SCHEMA  Defines properties for @AllStabilityMarginData class

%  Author(s): John Glass
%  Revised:
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'),'AllStabilityMarginData',superclass);

% Public attributes
schema.prop(c, 'Stable',      'MATLAB array'); 
schema.prop(c, 'GainMargin',  'MATLAB array'); 
schema.prop(c, 'PhaseMargin', 'MATLAB array'); 
schema.prop(c, 'DelayMargin', 'MATLAB array'); 
schema.prop(c, 'GMFrequency', 'MATLAB array'); 
schema.prop(c, 'PMFrequency', 'MATLAB array');  
schema.prop(c, 'DMFrequency', 'MATLAB array'); 
schema.prop(c, 'GMPhase', 'MATLAB array'); 
schema.prop(c, 'PMPhase', 'MATLAB array'); 
schema.prop(c, 'Ts', 'MATLAB array');
p = schema.prop(c, 'FreqUnits', 'string');  % Frequency units
p.FactoryValue = 'rad/s';

p = schema.prop(c, 'TimeUnits', 'string');  % Time units
p.FactoryValue = 'seconds';

% RE: data units are 
%     frequency: FreqUnits 
%     magnitude: abs
%     phase: degrees
