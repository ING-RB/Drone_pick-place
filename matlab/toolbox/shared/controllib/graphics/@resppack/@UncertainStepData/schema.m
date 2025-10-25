function schema
%  SCHEMA  Defines properties for @UncertainTimeData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'UncertainTimeData');
c = schema.class(findpackage('resppack'), 'UncertainStepData', superclass);




