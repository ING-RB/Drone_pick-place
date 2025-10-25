function schema
%SCHEMA  Defines properties for @RelativeIndexPlot class

%  Copyright 2021 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('resppack');
c = schema.class(pkg, 'RelativeIndexPlot', findclass(pkg, 'sigmaplot'));
