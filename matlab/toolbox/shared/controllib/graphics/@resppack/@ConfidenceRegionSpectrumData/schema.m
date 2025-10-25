function schema
%  SCHEMA  Defines properties for @ConfidenceRegionSpectrumData class

%  Author(s): Craig Buhr
%  Copyright 1986-2011 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionSpectrumData', superclass);

% Public attributes

schema.prop(c, 'Data', 'MATLAB array');
% Struct Data(ny,nu).Magnitude
%                   .MagnitudeSD
%                   .Frequency  
schema.prop(c, 'Ts', 'MATLAB array'); %Sample Time
schema.prop(c, 'TimeUnits', 'String'); 


