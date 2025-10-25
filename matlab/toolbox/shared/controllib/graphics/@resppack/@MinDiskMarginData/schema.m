function schema
% Data class for min disk margin

% Copyright 2020 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'),'MinDiskMarginData',superclass);

% Public attributes
schema.prop(c, 'DiskMargin', 'MATLAB array'); 
schema.prop(c, 'GainMargin',  'MATLAB array'); 
schema.prop(c, 'PhaseMargin', 'MATLAB array'); 
schema.prop(c, 'DMFrequency', 'MATLAB array'); 
schema.prop(c, 'Ts', 'MATLAB array');
p = schema.prop(c, 'FreqUnits', 'string');  % Frequency units
p.FactoryValue = 'rad/s';
p = schema.prop(c, 'TimeUnits', 'string');  % Time units
p.FactoryValue = 'seconds';

% RE: data units are 
%     frequency: FreqUnits 
%     magnitude: abs
%     phase: degrees
