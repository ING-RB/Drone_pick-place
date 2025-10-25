function schema
%  SCHEMA  Defines properties for @ConfidenceRegionTimeData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2015 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionTimeData', superclass);

% Public attributes
schema.prop(c, 'Data', 'MATLAB array'); 
% Struct Data(ny,nu,nD).Amplitude  
%                      .AmplitudeSD  
%                      .NumSD
%                      .Time  

schema.prop(c, 'Ts', 'MATLAB array'); %Sample Time
p = schema.prop(c, 'TimeUnits', 'string');
p.FactoryValue = 'seconds';


