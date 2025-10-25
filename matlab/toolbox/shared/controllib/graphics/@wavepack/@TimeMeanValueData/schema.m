function schema
%SCHEMA  Defines properties for @TimeMeanValueData class

%  Copyright 2015 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('wavepack'), 'TimeMeanValueData', superclass);

% Public attributes
schema.prop(c, 'Mean', 'MATLAB array');         % Mean Value
