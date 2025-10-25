function schema
%SCHEMA  Defines properties for @BodeStabilityMarginView class

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
pkg = findpackage('resppack');
c = schema.class(pkg, 'BodeStabilityMarginView', pkg.findclass('StabilityMarginView'));
