function schema
%  SCHEMA  Defines properties for @ConfidenceRegionStepTimeData class

%  Copyright 2015 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionTimeData');
schema.class(findpackage('resppack'), 'ConfidenceRegionSimTimeData', superclass);
