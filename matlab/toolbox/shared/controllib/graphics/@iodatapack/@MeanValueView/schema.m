function schema
%SCHEMA  Defines properties for @TimePeakAmpView class

%   Copyright 2013 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'PointCharView');
c = schema.class(findpackage('iodatapack'), 'MeanValueView', superclass);
