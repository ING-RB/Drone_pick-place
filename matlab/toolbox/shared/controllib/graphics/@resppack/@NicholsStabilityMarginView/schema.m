function schema
%SCHEMA  Defines properties for @NicholsStabilityMarginView class

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
pkg = findpackage('resppack');
c = schema.class(pkg, 'NicholsStabilityMarginView', ...
   pkg.findclass('StabilityMarginView'));