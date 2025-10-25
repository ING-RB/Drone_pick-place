function schema
% Defines properties for @ftransaction class.
% Transaction where undo/redo actions are explicitly defined
% as function handles.

%   Copyright 1986-2015 The MathWorks, Inc.
c = schema.class(findpackage('ctrluis'),'ftransaction');

% Editor data
schema.prop(c, 'Name', 'ustring');            % Name
schema.prop(c, 'UndoFcn', 'MATLAB array');   % Undo function
schema.prop(c, 'RedoFcn', 'MATLAB array');   % Redo function
