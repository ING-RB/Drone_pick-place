classdef ImportAttributesProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2020 The MathWorks, Inc.

    properties (Parameter)
        %ImportAttributes
        %    Enables importing XML node attributes as variables of the
        %    output table. Defaults to true.
        ImportAttributes(1, :) = true;
    end
    
    methods
        function func = set.ImportAttributes(func, rhs)
            if ~islogical(rhs) && ~isnumeric(rhs)
                error(message("MATLAB:io:xml:readstruct:IncorrectTypeImportAttributes"));
            else
                func.ImportAttributes = logical(rhs);
            end
        end
    end
end
