function schema
%SCHEMA  Defines properties for @DirectionalIndexWorstView class

%   Copyright 2021 The MathWorks, Inc.
wpack = findpackage('wavepack');
schema.class(findpackage('resppack'), ...
   'DirectionalIndexWorstView', findclass(wpack, 'FreqPeakGainView'));