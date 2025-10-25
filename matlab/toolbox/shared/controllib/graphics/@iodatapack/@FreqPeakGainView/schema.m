function schema
%SCHEMA  Defines properties for @FreqPeakGainView class

%   Author(s): Rajiv Singh
%   Copyright 2013 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('wavepack'), 'FreqPeakGainView');
schema.class(findpackage('iodatapack'), 'FreqPeakGainView', superclass);
