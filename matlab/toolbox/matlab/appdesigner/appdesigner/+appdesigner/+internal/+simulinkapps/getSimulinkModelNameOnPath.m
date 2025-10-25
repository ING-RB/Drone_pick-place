function validModelName = getSimulinkModelNameOnPath(modelName)
    %GETSIMULINKMODELNAMEONPATH Checks if the Simulink model is on the 
    % MATLAB path and has the correct casing
    % Input: modelName: a model name to check
    % Output: validModelName: the name of the validated model, or '' if the
    % model is not found
    
    % Copyright 2023-2024 The MathWorks, Inc.
    
    validModelName = '';
    % if there is a file extension, check if the file exists
    if contains(modelName, '.') && exist(modelName, 'file') == 4
        validModelName = modelName;
    % if there is only the file name without an extension, we need to
    % determine which extension is correct
    elseif exist(strcat(modelName, ".slx"), 'file') == 4
        validModelName = strcat(modelName, ".slx");
    elseif exist(strcat(modelName, ".mdl"), 'file') == 4
        validModelName = strcat(modelName, ".mdl");
    end

    if isempty(validModelName)
        error(message('MATLAB:appdesigner:appdesigner:SimulinkModelNotOnPath'));
    else
        expectedModel = which(validModelName);
        [~, expectedFileName, expectedExtension] = fileparts(expectedModel);
        if ~strcmp(validModelName, strcat(expectedFileName, expectedExtension))
            validModelName = '';
            error(message('MATLAB:appdesigner:appdesigner:SimulinkModelIncorrectCasing', modelName, expectedFileName, expectedModel));
        end
    end
end



