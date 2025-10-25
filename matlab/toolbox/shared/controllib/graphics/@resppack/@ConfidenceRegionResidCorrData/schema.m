function schema
%  SCHEMA  Defines properties for @ConfidenceRegionResidCorrData class

%  Copyright 2015 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionResidCorrData', superclass);

% Public attributes
schema.prop(c, 'Data', 'MATLAB array'); 
% Struct Data(ny,nu,nD).Amplitude  
%                      .SD
