function schema
%  SCHEMA  Defines properties for @bodeview class

%  Copyright 2013 The MathWorks, Inc.

% Register class (subclass)
superclass = findclass(findpackage('resppack'), 'bodeview');
schema.class(findpackage('iodatapack'), 'IOFrequencyView', superclass); 
