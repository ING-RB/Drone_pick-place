function schema
%  SCHEMA  Defines properties for @ConfidenceRegionImpulseTimeData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2011 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionTimeData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionImpulseTimeData', superclass);

p = schema.prop(c, 'ZeroMeanInterval', 'MATLAB array'); 
p.FactoryValue = true;


