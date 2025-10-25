function schema
%  SCHEMA  Defines properties for @rlplot class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2004 The MathWorks, Inc.

% Find parent package
pkg = findpackage('resppack');

% Register class (subclass)
c = schema.class(pkg, 'rlplot', findclass(pkg, 'pzplot'));