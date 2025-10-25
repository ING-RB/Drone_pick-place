function schema
%SCHEMA  Defines properties for @pzview class

%  Copyright 1986-2020 The MathWorks, Inc.
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('resppack'), 'hsvview', superclass);

% Class attributes
p = schema.prop(c, 'FiniteSV', 'MATLAB array');    % bar chart for finite HSV (blue)
p.SetFunction = @localConvertToHandle;
p = schema.prop(c, 'InfiniteSV', 'MATLAB array');  % bar chart for infinite HSV (red)
p.SetFunction = @localConvertToHandle;
p = schema.prop(c, 'ErrorBnd', 'MATLAB array');  % error bound
p.SetFunction = @localConvertToHandle;

