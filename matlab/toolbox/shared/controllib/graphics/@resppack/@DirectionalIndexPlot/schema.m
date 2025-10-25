function schema
%SCHEMA  Defines properties for @DirectionalIndexPlot class

%  Copyright 2021 The MathWorks, Inc.

% Register class (subclass)
pkg = findpackage('resppack');
c = schema.class(pkg, 'DirectionalIndexPlot', findclass(pkg, 'RelativeIndexPlot'));
