function schema
% View class for min disk margin

% Copyright 2020 The MathWorks, Inc.

% Register class
pkg = findpackage('resppack');
schema.class(pkg, 'MinDiskMarginView', pkg.findclass('StabilityMarginView'));
