function schema
%  SCHEMA  Defines properties for @ConfidenceRegionResidTimeData class

%  Copyright 2015The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionImpulseTimeData');
schema.class(findpackage('resppack'), 'ConfidenceRegionResidTimeData', superclass);
