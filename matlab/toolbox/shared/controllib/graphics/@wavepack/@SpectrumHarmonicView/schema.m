function schema
%SCHEMA  Defines properties for @SpectrumHarmonicView class

% Author(s): Erman Korkut 18-Mar-2009
% Revised:
% Copyright 1986-2009 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wavepack'), 'FreqPeakGainView');
c = schema.class(findpackage('wavepack'), 'SpectrumHarmonicView', superclass);
