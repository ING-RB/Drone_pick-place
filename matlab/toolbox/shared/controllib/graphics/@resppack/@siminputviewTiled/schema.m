function schema
%SCHEMA  Defines properties for @siminputview class

%  Copyright 1986-2004 The MathWorks, Inc.

% Parent class
pc = findclass(findpackage('wavepack'), 'timeview');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'siminputviewTiled',pc);
