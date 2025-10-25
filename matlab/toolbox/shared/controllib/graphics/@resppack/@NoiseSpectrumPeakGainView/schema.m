function schema
%SCHEMA  Defines properties for @NoiseSpectrumPeakGainView class

%   Copyright 2011 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wavepack'), 'FreqPeakGainView');
schema.class(findpackage('resppack'), 'NoiseSpectrumPeakGainView', superclass);
