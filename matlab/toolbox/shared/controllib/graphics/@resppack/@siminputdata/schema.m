function schema
%SCHEMA  Defines properties for @siminputdata class (input data)

%  Author(s): P. Gahinet
%  Copyright 1986-2004 The MathWorks, Inc.

% Parent class
pc = findclass(findpackage('wavepack'), 'timedata');

% Register class (subclass)
c = schema.class(findpackage('resppack'), 'siminputdata',pc);
