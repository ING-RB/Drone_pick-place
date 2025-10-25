function [informalInterfaceName, additionalArgs, callbackFunctions] = extractMappingData(dataMap, className)
    %EXTRACTMAPPINGDATA Looks into the cached component data for a specific class name. When found
    % returns it's informal interface function, Button -> uibutton
    % or any additional constructor arguments, uieditfield("numeric")
    % When nothing is found, the argued classname is returned instead.

%   Copyright 2024 The MathWorks, Inc.

    arguments
        dataMap
        className
    end

    lookupName = className;
    
    additionalArgs = [];

    callbackFunctions = [];

    if dataMap.isKey(lookupName)
        values = dataMap(lookupName);

        informalInterfaceName = values.InformalInterfaceName;

        if isfield(values, 'AdditionalArguments')
            additionalArgs = values.AdditionalArguments;
        end

        if isfield(values, 'CallbackFunctions')
            callbackFunctions = values.CallbackFunctions;
        end
    else
        informalInterfaceName = className;
    end
end
