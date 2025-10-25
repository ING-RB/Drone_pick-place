classdef AcceptsDatetimeTextType < matlab.io.internal.FunctionInterface
    %ACCEPTSDATETIMETEXTTYPE An interface for functions which accept a
    %DATETIMETYPE and a TEXTTYPE.
    
    % Copyright 2018-2024 The MathWorks, Inc.
    properties (Parameter)
        DatetimeType(1, :) = 'datetime'
        TextType(1, :) = 'char'
    end
    
    methods
        % -----------------------------------------------------------------
        function func = set.TextType(func,rhs)
            validateattributes(rhs, ["char", "string"], "nonempty", "", "TextType");
            func.TextType = validatestring(strip(rhs),{'char', 'string'});
        end
        % -----------------------------------------------------------------
        function func = set.DatetimeType(func,rhs)
            validateattributes(rhs, ["char", "string"], "nonempty", "", "DatetimeType");
            func.DatetimeType = validatestring(strip(rhs),{'datetime', ...
                'text', 'exceldatenum'});
        end
    end
end

