classdef RuntimeOutputException < matlab.internal.validation.RuntimeArgumentException
    %

    %   Copyright 2022 The MathWorks, Inc.

    methods
        function E = RuntimeOutputException(functionName, callSiteInfo, argumentPosition,...
                argumentName, errorID, errorMessage)
            E@matlab.internal.validation.RuntimeArgumentException(functionName, callSiteInfo,...
                argumentPosition, argumentName,...
                errorID, errorMessage);
        end

        function report = getReport(obj, varargin)
            % Avoid using RuntimeArgumentException's getReport because callSiteInfo used there 
            % is irrelevant for Output arguments
            report = getReport@matlab.internal.validation.Exception(obj, varargin{:});
        end
    end

    methods (Access=protected)
        function BuiltinThrow(obj)
            % type 2 exception doesn't print "Error using".
            % Setting the type value in BuiltinThrow makes sure both getReport and lasterr use
            % the same message.
            obj.type = {2,''};
            BuiltinThrow@matlab.internal.validation.Exception(obj);
        end
    end

    methods(Static)
        function E = createExceptionUsingID(functionName, callSiteInfo, argumentPosition,...
                argumentName, errorID, varargin)
            % Handle error messages in functionValidation message catalog.
            import matlab.internal.validation.RuntimeOutputException;
            [preambleObject, argumentPosition] = RuntimeOutputException.getPreambleObject(callSiteInfo, argumentPosition, argumentName);
            messageObject = message(errorID, preambleObject.getString, varargin{:});
            E = RuntimeOutputException(...
                functionName,...
                callSiteInfo,...
                argumentPosition,...
                argumentName,...
                errorID,...
                messageObject.getString);
        end

        function E = createExceptionUsingIDAndMessage(functionName, callSiteInfo, argumentPosition,...
                argumentName, errorID, errorMessage)
            import matlab.internal.validation.RuntimeOutputException;
            [preambleObject, argumentPosition] = RuntimeOutputException.getPreambleObject(callSiteInfo, argumentPosition, argumentName);
            errorMessage = sprintf('%s %s', preambleObject.getString, errorMessage);
            E = RuntimeOutputException(...
                functionName,...
                callSiteInfo,...
                argumentPosition,...
                argumentName,...
                errorID,...
                errorMessage);
        end

        function E = createExceptionUsingCaughtException(functionName, callSiteInfo,...
                argumentPosition, argumentName, CE)
            import matlab.internal.validation.RuntimeOutputException;
            [preambleObject, argumentPosition] = RuntimeOutputException.getPreambleObject(callSiteInfo, argumentPosition, argumentName);
            errorMessage = sprintf('%s %s', preambleObject.getString, CE.message);
            E = RuntimeOutputException(...
                functionName,...
                callSiteInfo,...
                argumentPosition,...
                argumentName,...
                CE.identifier,...
                errorMessage);
        end
    end

    methods(Static, Access=private)
        function [preambleObject, argumentPosition] = getPreambleObject(~, argumentPosition, argumentName)
            import matlab.internal.validation.RuntimeOutputException;
            msgId = RuntimeOutputException.PreambleID;
            msgArgs = {argumentName};
            % ignore callSiteInfo
            preambleObject = message(msgId, msgArgs{:});
        end
    end

    properties(Constant, Access=private)
        PreambleID = 'MATLAB:functionValidation:PreambleForRuntimeOutputError'
    end
end
