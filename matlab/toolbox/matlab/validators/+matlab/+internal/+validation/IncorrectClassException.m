classdef IncorrectClassException < matlab.internal.validation.DefinitionException
%

%   Copyright 2022 The MathWorks, Inc.

    properties
        InputOrOutput (1,1) string
    end
    
    methods
        function E = IncorrectClassException(functionName, errorID, className, inputOrOutput)
            E@matlab.internal.validation.DefinitionException(functionName, errorID, className);
            E.InputOrOutput = inputOrOutput;
        end

        %% type 2 exception doesn't print "Error using".
        function report = getReport(obj, varargin)
            if obj.InputOrOutput == "output"
                obj.type = {2,''};
            end
            report = getReport@matlab.internal.validation.DefinitionException(obj, varargin{:});
        end
    end
end
