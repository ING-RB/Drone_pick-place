function schema
%SCHEMA  Defines properties for @SigmaPeakRespView class

%   Author(s): John Glass
%   Copyright 1986-2004 The MathWorks, Inc.

% Register class (subclass)
wpack = findpackage('wavepack');
c = schema.class(findpackage('resppack'), ...
   'SigmaPeakRespView', findclass(wpack, 'FreqPeakGainView'));