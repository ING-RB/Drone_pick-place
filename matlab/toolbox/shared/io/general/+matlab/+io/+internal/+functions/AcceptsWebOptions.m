classdef AcceptsWebOptions < matlab.io.internal.FunctionInterface
    %ACCEPTWEBOPTIONS An interface for functions which accept a
    %WEBOPTIONS object.
    
    % Copyright 2021 The MathWorks, Inc.
    properties (Parameter) 
        WebOptions = [];
    end
    
    methods
        function func = set.WebOptions(func,rhs)
            if isa(rhs, "weboptions")
                func.WebOptions = rhs;
            else
                error(message('MATLAB:io:common:validation:ExpectedWeboptions'))
            end
        end
    end
end