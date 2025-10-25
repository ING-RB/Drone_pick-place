function schema
%SCHEMA  Defines properties for @TransientTimeView class.

%   Copyright 2021 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'SettleTimeView');
schema.class(findpackage('resppack'), 'TransientTimeView', superclass);
