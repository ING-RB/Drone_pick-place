function schema
%  SCHEMA  Defines properties for @ConfidenceRegionResidMagPhaseData class

%  Copyright 2015 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionMagPhaseData');
schema.class(findpackage('resppack'), 'ConfidenceRegionResidMagPhaseData', superclass);
