function varExists = existsInGlobalScope(model, varName)
%This function is for internal use only. It may be removed in the future.

%EXISTSINGLOBALSCOPE Check for existence of variable in global scope
%   If the MODEL input is empty, the existence will be checked in the
%   base workspace. Otherwise, the variable existence will be queried in
%   the global scope through the existsInGlobalScope function.

%   Copyright 2018-2019 The MathWorks, Inc.

    modelName = convertStringsToChars(model);
    varName = convertStringsToChars(varName);

    if isempty(modelName)
        % Always evaluate in base workspace
        varExists = evalin('base',['exist(''',varName,''',''var'');']) == 1;
    else
        % Convert the model name to a handle before calling
        % existsInGlobalScope. This ensures that load_system will not be
        % called and makes edge cases work, e.g. when the model is being
        % closed.
        modelHandle = get_param(modelName, 'Handle');

        % Pass expression to standard existsInGlobalScope function
        varExists = logical(existsInGlobalScope(modelHandle, varName));
    end
end
