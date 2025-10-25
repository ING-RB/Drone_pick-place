function schema
%  SCHEMA  Defines properties for @TimeInitialValueData class

%  Author(s): Erman Korkut 25-Mar-2009
%  Revised:
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('resppack'), 'TimeFinalValueData');
c = schema.class(findpackage('resppack'), 'TimeInitialValueData', superclass);

