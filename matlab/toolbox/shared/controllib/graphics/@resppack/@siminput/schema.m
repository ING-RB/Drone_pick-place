function schema
%SCHEMA  Defines properties for @siminput class

%  Copyright 1986-2015 The MathWorks, Inc.

superclass = findclass(findpackage('wavepack'), 'waveform');
c = schema.class(findpackage('resppack'), 'siminput', superclass);

schema.prop(c, 'ChannelName', 'MATLAB array');   % input channel names
p = schema.prop(c, 'Interpolation', 'string');    % interpolation method
p.FactoryValue = 'auto';
