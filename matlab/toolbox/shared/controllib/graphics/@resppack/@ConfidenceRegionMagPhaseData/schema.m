function schema
%  SCHEMA  Defines properties for @ConfidenceRegionMagPhaseData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2011 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionMagPhaseData', superclass);

% Public attributes

schema.prop(c, 'Data', 'MATLAB array');
% Struct Data(ny,nu).Magnitude
%                   .MagnitudeSD
%                   .Phase
%                   .PhaseSD
%                   .Frequency  


schema.prop(c, 'Ts', 'MATLAB array'); %Sample Time

schema.prop(c, 'TimeUnits', 'String'); 


