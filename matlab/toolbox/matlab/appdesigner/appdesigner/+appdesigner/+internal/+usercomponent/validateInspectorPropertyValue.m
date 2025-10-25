function [className, defaultValue, inferredDefaultValue, inferredRenderer] = validateInspectorPropertyValue(propInfo)
    % VALIDATEINSPECTORPROPERTYVALUE Validates the default value for a
    % property edited from the inspector.
    %
    %   propInfo is a struct with the fields:
    %       propInfo.ClassName - the class/data type for the property
    %       propInfo.DefaultValue - the default value
    %       propInfo.Name - the property name
    %       propInfo.Size - {1x2} cell array of the property size
    %       propInfo.ValidationFunctions - cell array of validation
    %           function strings: {'mustBeLessThan(propName, 10)'}

    % Copyright 2021-2023 The MathWorks, Inc.

    if (islogical(propInfo.InferredDefaultValue))
        propInfo.DefaultValue = propInfo.UserEnteredValue;
    elseif (isnumeric(propInfo.InferredDefaultValue)) && ~islogical(propInfo.UserEnteredValue)
        propInfo.DefaultValue = appdesservices.internal.util.convertClientNumberToServerNumber(propInfo.UserEnteredValue);
    elseif iscell(propInfo.InferredDefaultValue)
        propInfo.DefaultValue = propInfo.UserEnteredValue;
    else
        propInfo.DefaultValue = sprintf('''%s''', propInfo.UserEnteredValue);
    end
    [className, defaultValue, inferredDefaultValue, inferredRenderer] = appdesigner.internal.usercomponent.validateAndInferPropertyDetails(propInfo);
end
