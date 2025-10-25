function schema
%  SCHEMA  Defines properties for @ConfidenceRegionData class
%  Abstract Class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionData', superclass);

% Public attributes
p = schema.prop(c, 'NumSD', 'MATLAB array'); 
p.FactoryValue = 1;


