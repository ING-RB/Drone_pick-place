function schema
%SCHEMA  Defines properties for @RelativeIndexView class.

%  Copyright 2021 The MathWorks, Inc.
pkg = findpackage('resppack');
superclass = findclass(pkg, 'sigmaview');
schema.class(pkg, 'DirectionalIndexView', superclass);
