function schema
%SCHEMA  Class definition for @wavechar (waveform characteristics).

%  Copyright 1986-2004 The MathWorks, Inc.
superclass = findclass(findpackage('wrfc'),'dataview');
c = schema.class(findpackage('wavepack'), 'wavechar', superclass);

schema.prop(c,'Identifier','string');   % Constraint type identifier