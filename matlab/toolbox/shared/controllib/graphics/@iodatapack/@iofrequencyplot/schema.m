function schema
%SCHEMA  Definition of @iotimeplot class (time based IO data plot).

%  Copyright 2013 The MathWorks, Inc.

% Register class 
ppkg = findpackage('resppack');
pkg = findpackage('iodatapack');
c = schema.class(pkg, 'iofrequencyplot', findclass(ppkg, 'bodeplot'));
% Class attributes
schema.prop(c, 'IOSize', 'MATLAB array'); % [ny nu]

p = schema.prop(c,'UnitsContainer','MATLAB array');
p.AccessFlags.PublicGet = 'on';
p.AccessFlags.PublicSet = 'on';
