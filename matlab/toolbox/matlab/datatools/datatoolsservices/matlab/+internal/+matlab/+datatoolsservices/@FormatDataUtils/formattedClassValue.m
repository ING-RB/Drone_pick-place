% Gets the formatted class value, which is used for icon selection

% Copyright 2024 The MathWorks, Inc.

function formattedVal = formattedClassValue(editValue, primaryDataType)
    arguments
        editValue
        primaryDataType = 'tall' % Default to tall type, this could also be gpuArray/distributed etc.
    end

    % Special handling for tall and distributed variables.  The editValue will be something like
    % 'tall duration' or 'tall duration (unevaluated)', so the formattedVal will be 'tall_duration'
    formattedVal = primaryDataType;
    dataTypeComponents = strsplit(editValue);
    if strfind(dataTypeComponents{end}, '(') == 1
        underlyingCls = dataTypeComponents{end-1};
    else
        underlyingCls = dataTypeComponents{end};
    end
    if ~isempty(underlyingCls) && ~strcmp(underlyingCls, primaryDataType)
        if any(strcmp(dataTypeComponents, "sparse"))
            formattedVal = [strtrim(extractAfter(primaryDataType, 'sparse')) '_sparse'];
        else
            formattedVal = [primaryDataType '_' underlyingCls];
        end
    end
end
