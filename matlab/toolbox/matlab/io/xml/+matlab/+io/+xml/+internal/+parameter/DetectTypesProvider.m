classdef DetectTypesProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2020 The MathWorks, Inc.

    properties (Parameter)
        %DetectTypes
        %    Enables datatype detection. Defaults to true.
        DetectTypes(1, 1) = true;
    end
    
    methods
        function func = set.DetectTypes(func, rhs)
            if ~islogical(rhs) && ~isnumeric(rhs)
                error(message("MATLAB:io:xml:readstruct:IncorrectTypeDetectTypes"));
            else
                func.DetectTypes = logical(rhs);
            end
        end
    end
end
