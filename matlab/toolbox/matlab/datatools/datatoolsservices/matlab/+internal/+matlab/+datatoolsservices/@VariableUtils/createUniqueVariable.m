% This method creates a default variable (double with value '0') with a unique
% name prefixed with 'unnamed' in the provided workspace. For E.g
% >>unnamed=0;openvar('unnamed'); If no workspace is provided, we evalin in
% 'debug' to ensure that this is executed in the user's debug workspace.

% Copyright 2020-2022 The MathWorks, Inc.

function createUniqueVariable(workspace)
    if nargin < 1 || (ischar(workspace) && strcmp(workspace, 'caller'))
        % 'debug' workspace would be where the user has an active cmd prompt,
        % default to this.
        workspace = 'debug';
    end
    fnames = evalin(workspace, 'who');
    uniqueName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName('unnamed', fnames);
    variableCreationCmd = sprintf('%s=0;openvar(''%s'');',uniqueName, uniqueName);
    evalin(workspace, variableCreationCmd);
end