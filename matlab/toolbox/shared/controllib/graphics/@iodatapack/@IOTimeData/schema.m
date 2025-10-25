function schema
%  SCHEMA  Defines properties for @IOTimeData class.

%  Copyright 2013-2015 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wrfc'), 'data');

% Register class (subclass)
c = schema.class(findpackage('iodatapack'), 'IOTimeData', supclass);

% Public attributes
schema.prop(c, 'Focus', 'MATLAB array');   % Focus (preferred time range)
schema.prop(c, 'InputData', 'MATLAB array'); % Vector of timeseries 
schema.prop(c, 'OutputData', 'MATLAB array'); % Vector of timeseries 
schema.prop(c, 'IsReal', 'bool'); % is data real? (for plotting complex iddata)
%schema.prop(c, 'IsTimeCommon', 'bool');    % all signals are sampled to same time vector
