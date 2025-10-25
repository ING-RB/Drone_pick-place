function schema
%SCHEMA  Defines properties for @FreqPeakGainData class.
%
%  Peak magnitude characteristic (associated with @IOFrequencyData).

%  Copyright 2013 The MathWorks, Inc.

% Find parent package

% Register class
superclass = findclass(findpackage('wavepack'), 'FreqPeakGainData');
schema.class(findpackage('iodatapack'), 'FreqPeakGainData', superclass);
