function schema
%  SCHEMA  Defines properties for @ConfidenceRegionStepTimeData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionTimeData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionStepTimeData', superclass);




