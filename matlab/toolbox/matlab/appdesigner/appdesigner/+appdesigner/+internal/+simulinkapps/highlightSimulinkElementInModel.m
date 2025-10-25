function isModelValid = highlightSimulinkElementInModel(blockPath, portNumber)
    %HIGHLIGHTSIMULINKELEMENTINMODEL highlights the signal that the user
    % selected in App Designer in the Simulink model

    % Copyright 2023 MathWorks, Inc.

    isModelValid = false;
    modelName = split(blockPath, '/');
    modelName = modelName(1);
    if exist(strcat(modelName, ".slx"), 'file') == 4 || exist(strcat(modelName, ".mdl"), 'file') == 4
        isModelValid = true;
        % Only support highlighting signals since it's not possible to know
        % where variables are in the model
        elementType = BindMode.BindableTypeEnum.SLSIGNAL.char;
        
        % the model must be open for the signal to be highlighted
        open_system(modelName);
        modelHandle = get_param(modelName, 'Handle');
        blockHandle = get_param(blockPath, 'Handle');

        BindMode.utils.highlightElementInModel(modelHandle{1}, elementType, blockHandle, str2double(portNumber));
    end
end



