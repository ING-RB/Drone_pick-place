function schema
%SCHEMA  Defines properties for @TimePeakAmpData class

%  Copyright 2013 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('iodatapack'), 'TimePeakAmpData', superclass);

% Public attributes
schema.prop(c, 'Time', 'MATLAB array');         % Time where amplitude peaks
schema.prop(c, 'PeakResponse', 'MATLAB array'); % Amplitude at peak
schema.prop(c, 'TimeUnit', 'MATLAB array');
