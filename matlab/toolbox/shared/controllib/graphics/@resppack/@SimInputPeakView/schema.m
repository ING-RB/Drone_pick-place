function schema
%SCHEMA  Defines properties for @SimInputPeakView class.

%   Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wavepack'), 'TimePeakAmpView');
c = schema.class(findpackage('resppack'), 'SimInputPeakView', superclass);
