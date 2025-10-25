function [ctorInput, extraLines, postChildrenLines, assignedCallbacks] = getComponentPropertyAssignments(className, additionalArguments, properties, codeName, callbackFunctions, isUac, isLoad)
    %GETCOMPONENTPROPERTYASSIGNMENTS Process component properties into component initialization assignments.

%   Copyright 2024 The MathWorks, Inc.

    arguments
        className
        additionalArguments
        properties {}
        codeName
        callbackFunctions
        isUac logical
        isLoad logical = false
    end

    count = length(properties);

    inputLength = count;

    strBuilderIndex = 1;
    if ~isempty(additionalArguments)
        strBuilder = strings(1, inputLength + 1);
        strBuilder(strBuilderIndex) = append('''', additionalArguments, '''');
        strBuilderIndex = strBuilderIndex + 1;
    else
        strBuilder = strings(1, inputLength);
    end

    extraLinesIndex = 1;
    extraLines = strings(1, inputLength);

    postChildrenIndex = 1;
    postChildrenLines = strings(1, inputLength);

    assignedCallbacks = [];

    if isLoad
        assignedCallbacks = repmat(struct('Callback', '', 'Name', ''), 1, inputLength);
        callbackIndex = 1;
    end

    for i = 1:count
        [propertyArgument, extra, postChildren, isCallbackProperty] = appdesigner.internal.artifactgenerator.translateProperty(codeName, properties(i), callbackFunctions, className, isUac, isLoad);

        if ~isempty(propertyArgument)
            strBuilder(strBuilderIndex) = propertyArgument;
            strBuilderIndex = strBuilderIndex + 1;
        end

        if ~isempty(extra)
            extraLines(extraLinesIndex) = extra;
            extraLinesIndex = extraLinesIndex + 1;
        end

        if ~isempty(postChildren)
            postChildrenLines(postChildrenIndex) = postChildren;
            postChildrenIndex = postChildrenIndex + 1;
        end

        if isLoad && isCallbackProperty
            assignedCallbacks(callbackIndex).Callback = properties(i).PropertyName;
            assignedCallbacks(callbackIndex).Name = properties(i).PropertyValue;
            callbackIndex = callbackIndex + 1;
        end
    end

    if isLoad
        assignedCallbacks = assignedCallbacks(1:callbackIndex - 1);
    end

    ctorInput = strjoin(strBuilder(1:strBuilderIndex - 1), ', ');
    extraLines = extraLines(1:extraLinesIndex - 1);
    postChildrenLines = postChildrenLines(1:postChildrenIndex - 1);
end
