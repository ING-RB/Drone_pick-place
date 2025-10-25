classdef RuntimeArgumentException < matlab.internal.validation.Exception
%

%   Copyright 2019-2024 The MathWorks, Inc.

    properties
        FunctionName     (1,1) string
        ArgumentName     (1,1) string
        ArgumentPosition (1,1) int32
        CallSiteInfo     struct {mustBeScalarOrEmpty}
    end
    
    properties (Access = private)
        OriginalStack    struct
    end
    
    methods(Static)
        function fn = getConversionExceptionCreater(isDefault, isNamed, inputOrOutput)
            if isDefault
                fn = @matlab.internal.validation.DefaultValueException.createExceptionUsingIDAndMessage;
            elseif isNamed
                fn = @matlab.internal.validation.RuntimeNameValueException.createExceptionUsingIDAndMessage;
            elseif inputOrOutput == "input"
                fn = @matlab.internal.validation.RuntimePositionalException.createExceptionUsingIDAndMessage;
            else
                fn = @matlab.internal.validation.RuntimeOutputException.createExceptionUsingIDAndMessage;
            end
        end
        
        function fn = getSizeConversionExceptionCreater(isDefault, isNamed, inputOrOutput)
            if isDefault
                fn = @matlab.internal.validation.DefaultValueException.createExceptionUsingIDAndMessage;
            elseif isNamed
                fn = @matlab.internal.validation.RuntimeNameValueException.createExceptionUsingIDAndMessage;
            elseif inputOrOutput == "input"
                fn = @matlab.internal.validation.RuntimePositionalException.createExceptionUsingIDAndMessage;
            else
                fn = @matlab.internal.validation.RuntimeOutputException.createExceptionUsingIDAndMessage;
            end
        end
        
        function fn = getValidatorExceptionCreater(isDefault, isNamed, inputOrOutput)
            if isDefault
                fn = @matlab.internal.validation.DefaultValueException.createExceptionUsingCaughtException;
            elseif isNamed
                fn = @matlab.internal.validation.RuntimeNameValueException.createExceptionUsingCaughtException;
            elseif inputOrOutput == "input"
                fn = @matlab.internal.validation.RuntimePositionalException.createExceptionUsingCaughtException;
            else
                fn = @matlab.internal.validation.RuntimeOutputException.createExceptionUsingCaughtException;
            end
        end
    end
    
    methods
        function E = RuntimeArgumentException(functionName, callSiteInfo, argumentPosition,...
                                              argumentName, errorID, errorMessage)
            E@matlab.internal.validation.Exception(errorID, errorMessage);
            E.FunctionName = functionName;
            E.CallSiteInfo = callSiteInfo;
            E.ArgumentPosition = argumentPosition;
            E.ArgumentName = argumentName;
            E.OriginalStack = struct.empty;
        end
        
        function tf = hasBeenThrownMoreThanOnce(obj)
            origStack = obj.OriginalStack;
            tf = ~isempty(origStack) && ~isequal(origStack, obj.enhancedstack);
        end
        
        function report = getReport(obj, varargin)
            report = getReport@MException(obj, varargin{:});
            try
                stack = obj.enhancedstack;
                callSiteInfo = obj.CallSiteInfo;
                argPos = obj.ArgumentPosition;

                % Use the MException base class report if:
                % - callSiteInfo is not scalar or there are not at least two stack frames,
                %   as something is wrong or unexpected.
                % - callSiteInfo does not have information for the bad input argument.
                % - exception has been thrown more than once, since the stack no longer
                %   applies to the original, invalidated FAV function.
                useMExceptionReport = numel(stack) < 2 ...
                    || ~isscalar(callSiteInfo) ...
                    || numel(callSiteInfo.ArgLocation) < argPos ...
                    || obj.hasBeenThrownMoreThanOnce;

                if useMExceptionReport
                    return;
                end

                lineNum = callSiteInfo.ArgLocation(argPos).LineNumber;
                matlabCode = getMatlabCode(stack, lineNum);
                if matlabCode.line == ""
                    return;
                end

                indent = ' ';
                msgTxt = strip(matlab.internal.display.printWrapped(obj.message), 'right');
                startColumnNum = callSiteInfo.ArgLocation(argPos).ColumnNumber;
                endColumnNum = startColumnNum + ...
                    matlab.lang.internal.diagnostic.inputArgumentLength(matlabCode.all, lineNum, startColumnNum);
                underline = matlab.lang.internal.diagnostic.getUnderlineString(matlabCode.line, startColumnNum, endColumnNum);
                codeAndUnderlineBlock = append(indent, matlabCode.line, newline, indent, underline, newline);
                report = insertBefore(report, msgTxt, codeAndUnderlineBlock);
            catch e
                % Catching to a variable (even if unused) prevents drool to lasterror.
            end
        end
    end

    methods (Access = protected)
        function BuiltinThrow(obj)
            if isempty(obj.OriginalStack)
                obj = obj.setOriginalStack(obj.enhancedstack);
            end
            BuiltinThrow@matlab.internal.validation.Exception(obj);
        end
    end

    methods (Access = private)
        function obj = setOriginalStack(obj, stack)
            obj.OriginalStack = stack;
        end
    end
    
end

function code = getMatlabCode(stack, lineNum)
    % If invoked from the command line, there are exactly two stack frames:
    % 2. The FAV function that errored.
    % 1. The eval frame typed in at the command prompt containing the
    %    invalid invocation of the FAV function.

    wasInvokedFromCommandLine = (numel(stack) == 2);

    callFrame = stack(2);
    file = callFrame.file;
    if wasInvokedFromCommandLine
        code.all = callFrame.statement;
        allLines = splitlines(code.all);
        code.line = allLines{lineNum};
    elseif lineNum == 0 || isempty(file)
        code.all = "";
        code.line = "";
    else
        % We use readLineFromMatlabFile to read the file again for the line in case
        % of a P-file and matching M-file.  In that case, we do not have the column
        % information to parse the entire file and determine the endColumn, so it
        % is ok if we fileread the P-file instead of the M-file, because, at best,
        % we can only point to the first character of the input due to the missing
        % column information.
        code.all = fileread(file);
        code.line = matlab.lang.internal.diagnostic.readLineFromMatlabFile(file, lineNum);
    end
end
