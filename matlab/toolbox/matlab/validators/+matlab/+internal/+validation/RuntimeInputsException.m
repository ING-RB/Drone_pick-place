classdef RuntimeInputsException < matlab.internal.validation.Exception
%

%   Copyright 2019-2020 The MathWorks, Inc.

    properties
        FunctionName (1,1) string     
    end
    
    methods
        function E = RuntimeInputsException(functionName, errorID, errorMessage)
            E@matlab.internal.validation.Exception(errorID, errorMessage);
            E.FunctionName = functionName;
        end
    end
    
    methods(Static)      
        % Second input is the number of required arguments. If we do decide to use it
        % in the future, make this class abstract and create subclasses to
        % include more specifics, e.g. number of required arguments.
        function E = createInputsExceptionUsingMessageAndSuffix(functionName, ~, errorID, errorMessage, suffix)
            import matlab.internal.validation.RuntimeInputsException;
            preamble = message(RuntimeInputsException.PreambleID).getString;
            maybeNewLine = "";
            if ~isempty(suffix)
               maybeNewLine = newline; 
            end
            errorMessage = sprintf('%s %s%s%s', preamble, errorMessage, maybeNewLine, suffix);
            E = matlab.internal.validation.RuntimeInputsException(functionName, errorID, errorMessage);
        end
    
        function E = createInputsExceptionUsingIDAndMessage(functionName, ~, errorID, errorMessage)
            import matlab.internal.validation.RuntimeInputsException;
            preamble = message(RuntimeInputsException.PreambleID).getString;
            errorMessage = sprintf('%s %s', preamble, errorMessage);
            E = matlab.internal.validation.RuntimeInputsException(functionName, errorID, errorMessage);
        end
        
        function E = createExceptionUsingID(functionName, errorID, varargin)
            import matlab.internal.validation.RuntimeInputsException;
            preamble = message(RuntimeInputsException.PreambleID).getString;
            messageObject = message(errorID, preamble, varargin{:});
            E = matlab.internal.validation.RuntimeInputsException(functionName, errorID, messageObject.getString);
        end
    end
    
    properties(Constant, Access=private)
        PreambleID = 'MATLAB:functionValidation:PreambleForRuntimeInputError'
    end
end
