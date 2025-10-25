classdef Constants
    %CONSTANTS contain constant values for the property inspector section.

    % Copyright 2020-2021 The MathWorks, Inc.

    properties
        %% ERROR Data
        ErrorText = string(message("transportapp:appspace:propertyinspector:ErrorText").getString)
        ErrorSize = [0 0]
        ErrorDataType = string(message("transportapp:appspace:propertyinspector:ErrorDataType").getString)
    end
end