function schema
%SCHEMA  Defines properties for @TimeMeanValueView class

%   Copyright 2015 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'PointCharView');
c = schema.class(findpackage('wavepack'), 'TimeMeanValueView', superclass);
