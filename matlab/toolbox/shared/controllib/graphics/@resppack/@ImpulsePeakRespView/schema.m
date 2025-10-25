function schema
%SCHEMA  Defines properties for @ImpulsePeakRespView class

%   Copyright 2023 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wavepack'), 'TimePeakAmpView');

% Register class (subclass)
schema.class(findpackage('resppack'), 'ImpulsePeakRespView', supclass);