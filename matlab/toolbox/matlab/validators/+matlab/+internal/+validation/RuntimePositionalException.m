classdef RuntimePositionalException < matlab.internal.validation.RuntimeArgumentException
%

%   Copyright 2019-2021 The MathWorks, Inc.

    methods
        function E = RuntimePositionalException(functionName, callSiteInfo, argumentPosition,...
                                                argumentName, errorID, errorMessage)
            E@matlab.internal.validation.RuntimeArgumentException(functionName, callSiteInfo,...
                                                              argumentPosition, argumentName,...
                                                              errorID, errorMessage);
        end
    end
    
    methods(Static)
        function E = createExceptionUsingID(functionName, callSiteInfo, argumentPosition,...
                                            argumentName, errorID, varargin)
        % Handle error messages in functionValidation message catalog.
            import matlab.internal.validation.RuntimePositionalException;
            [preambleObject, argumentPosition] = RuntimePositionalException.getPreambleObject(callSiteInfo, argumentPosition);
            messageObject = message(errorID, preambleObject.getString, varargin{:});
            E = RuntimePositionalException(...
                functionName,...
                callSiteInfo,...
                argumentPosition,...
                argumentName,...
                errorID,...
                messageObject.getString);
        end
       
        function E = createExceptionUsingIDAndMessage(functionName, callSiteInfo, argumentPosition,...
                                                      argumentName, errorID, errorMessage)
            import matlab.internal.validation.RuntimePositionalException;
            [preambleObject, argumentPosition] = RuntimePositionalException.getPreambleObject(callSiteInfo, argumentPosition);
            errorMessage = sprintf('%s %s', preambleObject.getString, errorMessage);
            E = RuntimePositionalException(...
                functionName,...
                callSiteInfo,...
                argumentPosition,...
                argumentName,...
                errorID,...
                errorMessage);
        end

        function E = createExceptionUsingCaughtException(functionName, callSiteInfo,...
                                                         argumentPosition, argumentName, CE)
            import matlab.internal.validation.RuntimePositionalException;
            [preambleObject, argumentPosition] = RuntimePositionalException.getPreambleObject(callSiteInfo, argumentPosition);
            errorMessage = sprintf('%s %s', preambleObject.getString, CE.message);
            E = RuntimePositionalException(...
                functionName,...
                callSiteInfo,...
                argumentPosition,...
                argumentName,...
                CE.identifier,...
                errorMessage);
        end
    end
    
    methods(Static, Access=private)
        function [preambleObject, argumentPosition] = getPreambleObject(callSiteInfo, argumentPosition)
            import matlab.internal.validation.RuntimePositionalException;
            msgId = RuntimePositionalException.PreambleID;
            msgArgs = {argumentPosition};
            if isscalar(callSiteInfo)
                switch callSiteInfo.FunctionInvocationType
                case "CLASS_METHOD"
                    if argumentPosition == 1
                        msgId = 'MATLAB:functionValidation:PreambleForRuntimePositionalErrorWithDotInvocationOfInvalidObject';
                        msgArgs = {};
                    else
                        msgArgs = {argumentPosition - 1};
                    end
                case "FEVAL"
                    argumentPosition = argumentPosition + 1;
                    msgArgs = {argumentPosition};
                end
            end
            preambleObject = message(msgId, msgArgs{:});
        end
    end
    
    properties(Constant, Access=private)
        PreambleID = 'MATLAB:functionValidation:PreambleForRuntimePositionalError'
    end
end
