function schema
%  SCHEMA  Defines properties for @NyquistStabilityMarginView class

%  Copyright 1986-2004 The MathWorks, Inc.

% Register class
pkg = findpackage('resppack');
c = schema.class(pkg, 'NyquistStabilityMarginView', ...
   pkg.findclass('StabilityMarginView'));