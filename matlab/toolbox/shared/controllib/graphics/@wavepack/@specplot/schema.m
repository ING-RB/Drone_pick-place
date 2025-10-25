function schema
%SCHEMA  Definition of @specplot class (frequency spectrum plot).

%  Author(s): P. Gahinet
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class 
pkg = findpackage('wavepack');
c = schema.class(pkg, 'specplot', findclass(pkg, 'waveplot'));