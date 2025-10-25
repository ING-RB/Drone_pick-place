function schema
%SCHEMA  Defines properties for @IOTimeView class.

%  Copyright 2013 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('iodatapack'), 'IOTimeView', superclass);

% Class attributes
schema.prop(c, 'Curves', 'MATLAB array');  % Handles of HG line groups (matrix)
