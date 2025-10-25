function schema
%  SCHEMA  Defines properties for @ConfidenceRegionFreqData class

%  Author(s): Craig Buhr
%  Revised:
%  Copyright 1986-2010 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'ConfidenceRegionData');
c = schema.class(findpackage('resppack'), 'ConfidenceRegionFreqData', superclass);


schema.prop(c, 'Data', 'MATLAB array');
% Struct Data.Response   [nFreq-by-ny-by-nu]
%            .Frequency  [nFreq-by-1]
%            .Cov        [ny-by-nu-nFreq-by-2-by-2]

schema.prop(c, 'EllipseData', 'MATLAB array');

schema.prop(c, 'Ts',      'MATLAB array');       % Sampling Time
p =schema.prop(c, 'TimeUnits', 'string');  % 
p.FactoryValue = 'seconds';


p = schema.prop(c, 'ConfidenceDisplaySampling', 'MATLAB array');
p.FactoryValue = 5;
