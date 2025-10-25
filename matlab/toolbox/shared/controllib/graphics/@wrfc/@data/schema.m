function schema
%SCHEMA  Definition of @data interface (abstract data container).

%  Copyright 1986-2004 The MathWorks, Inc.

% Register class 
pkg = findpackage('wrfc');
c = schema.class(pkg, 'data');

% Public properties
schema.prop(c, 'Parent', 'handle');    % Parent data object (used, e.g., for resp. char.)
schema.prop(c, 'Exception', 'bool');   % True when data is invalid (badly sized, ill defined,...)
schema.prop(c, 'ExceptionReason', 'MATLAB array');   % Reason for exception, message class

% Private attributes
p = schema.prop(c, 'Listeners', 'handle vector');
set(p, 'AccessFlags.PublicGet', 'off', 'AccessFlags.PublicSet', 'off');
