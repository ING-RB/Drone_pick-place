function outputValue = convertStringToOriginalTextType(outputValue, originalInput)
%

%   Copyright 2017-2023 The MathWorks, Inc.

    if ischar(originalInput)
        if ismissing(outputValue)
            outputValue = '';
        else
            outputValue = char(outputValue);
        end
    elseif iscell(originalInput)
        outputValue = cellstr(outputValue);
    end
end
