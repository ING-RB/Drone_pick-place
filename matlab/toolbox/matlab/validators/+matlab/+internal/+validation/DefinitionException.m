classdef DefinitionException < matlab.internal.validation.Exception
%

%   Copyright 2019-2022 The MathWorks, Inc.

    properties
        FunctionName (1,1) string
    end
    
    methods
        function E = DefinitionException(functionName, errorID, varargin)
            preambleObject = message('MATLAB:functionValidation:PreambleForDefinitionError', functionName);
            messageObject = message(errorID, preambleObject.getString, varargin{:});
            E@matlab.internal.validation.Exception(errorID, messageObject.getString);
            E.FunctionName = functionName;
        end
    end
end
