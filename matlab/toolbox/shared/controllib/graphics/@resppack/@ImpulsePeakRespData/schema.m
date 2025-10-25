function schema
% 

%  Copyright 2022 The MathWorks, Inc.

% Find parent class (superclass)
supclass = findclass(findpackage('wavepack'), 'TimePeakAmpData');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'ImpulsePeakRespData', supclass);
