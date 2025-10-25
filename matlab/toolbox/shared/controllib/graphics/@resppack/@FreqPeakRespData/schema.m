function schema
%SCHEMA  Defines properties for @FreqPeakRespData class

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'data');
c = schema.class(findpackage('resppack'), 'FreqPeakRespData', superclass);

% Public attributes
schema.prop(c, 'Frequency', 'MATLAB array');     % Frequency where gain peak
schema.prop(c, 'PeakResponse', 'MATLAB array');  % Complex response at peak
