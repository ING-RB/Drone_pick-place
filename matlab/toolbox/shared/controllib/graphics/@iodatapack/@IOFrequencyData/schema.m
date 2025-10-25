function schema
%   SCHEMA  Defines properties for @magphasedata class

%   Copyright 2013 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('resppack'), 'magphasedata');

% Register class (subclass)
c = schema.class(findpackage('iodatapack'), 'IOFrequencyData', supclass);
schema.prop(c, 'IOSize', 'MATLAB array');        % [ny nu]
