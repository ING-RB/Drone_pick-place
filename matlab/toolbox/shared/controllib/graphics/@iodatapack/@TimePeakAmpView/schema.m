function schema
%SCHEMA  Defines properties for @TimePeakAmpView class

%   Copyright 2013 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wavepack'), 'TimePeakAmpView');
schema.class(findpackage('iodatapack'), 'TimePeakAmpView', superclass);
