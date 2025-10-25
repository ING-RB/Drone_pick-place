function schema
%  SCHEMA  Defines properties for @TransientTimeData class

%   Copyright 2021 The MathWorks, Inc.
superclass = findclass(findpackage('resppack'), 'SettleTimeData');
schema.class(findpackage('resppack'), 'TransientTimeData', superclass);