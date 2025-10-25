function schema
%SCHEMA  Defines properties for @StepPeakRespView class

%   Author(s): John Glass
%   Copyright 1986-2004 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Find parent class (superclass)
supclass = findclass(findpackage('wavepack'), 'TimePeakAmpView');

% Register class (subclass)
c = schema.class(pkg, 'StepPeakRespView', supclass);