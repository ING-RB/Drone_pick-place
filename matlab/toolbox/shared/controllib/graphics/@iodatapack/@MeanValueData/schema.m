function schema
%SCHEMA  Defines properties for @TimePeakAmpData class

%  Copyright 2013 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('iodatapack'), 'MeanValueData', superclass);

% Public attributes
schema.prop(c, 'Mean', 'MATLAB array');         % Mean Value
