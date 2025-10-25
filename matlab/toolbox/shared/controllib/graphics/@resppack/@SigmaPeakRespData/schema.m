function schema
%SCHEMA  Defines properties for @SigmaPeakRespData class

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wavepack'), 'FreqPeakGainData');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'SigmaPeakRespData', supclass);
