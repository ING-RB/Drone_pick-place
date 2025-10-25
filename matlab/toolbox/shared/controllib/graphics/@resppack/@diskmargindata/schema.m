function schema
% Class definition.

%  Copyright 2020 The MathWorks, Inc.
superclass = findclass(findpackage('resppack'), 'magphasedata');
c = schema.class(findpackage('resppack'), 'diskmargindata', superclass);
schema.prop(c, 'DiskMargin', 'MATLAB array');  % ALPHA data
