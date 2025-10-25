function schema
% Defines properties for @transaction class.
% Extension of transaction to support custom 
% refresh method after undo/redo.

%   Copyright 1986-2015 The MathWorks, Inc.

% Register class 
c = schema.class(findpackage('ctrluis'),'transaction');

% Editor data
schema.prop(c, 'Name', 'ustring');                % name
schema.prop(c, 'Transaction', 'handle');          % handle.transaction
schema.prop(c, 'RootObjects', 'handle vector');   % Refresh action
