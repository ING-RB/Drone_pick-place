classdef AppAppendixComponentException < MException
    %APPAPPENDIXCOMPONENTEXCEPTION 

%   Copyright 2024 The MathWorks, Inc.

    properties (Access = private, Hidden)
        StackFrames struct
        CodeName string
        InitializationCodeLine string
    end

    methods
        function obj = AppAppendixComponentException(originalException, options, mInitFilepath, componentInitCode, appFileContent)
            arguments
                originalException MException
                options appdesigner.internal.apprun.AppOptions
                mInitFilepath
                componentInitCode
                appFileContent
            end

            stackFrame = appdesigner.internal.artifactgenerator.exception.AppAppendixComponentException.getMInitFrame(originalException.stack, mInitFilepath);

            obj@MException(originalException.identifier, originalException.message);

            if ~isempty(stackFrame)
                [codeName, initCodeLine] = appdesigner.internal.artifactgenerator.exception.AppAppendixComponentException.determineFailure(stackFrame, componentInitCode);

                obj.CodeName = codeName;
    
                obj.InitializationCodeLine = initCodeLine;
    
                appendixLinenumber = obj.determineAppendixLineNumber(appFileContent, codeName);
    
                obj.StackFrames = obj.createStackFrame(options.Filepath, appendixLinenumber);
    
                if appdesigner.internal.artifactgenerator.AppLogger.isDebug()
                    obj.StackFrames(2:length(originalException.stack) + 1) = originalException.stack(1:end);
                    obj.StackFrames = obj.StackFrames';
                end
            else
                % internal appdesigner exception occurred! Couldn't find a stack from the generated file.
                % This is a bug!
                obj.StackFrames = originalException.stack;
            end
        end
    end

    methods (Access = protected)
        function stack = getStack(obj)
            stack = obj.StackFrames;
        end
    end

    methods (Access = private, Static)
        function [codeName, initCodeLine] = determineFailure(stackFrame, componentInitCode)
            lines = split(componentInitCode, newline);

            failureLine = lines(stackFrame.line);

            parts = split(failureLine, ' = ');

            codeName = extractAfter(parts{1}, '.');

            initCodeLine = extractBefore(parts{2}, ';');
        end

        function stackFrame = getMInitFrame (stack, mInitFilepath)
            stackFrame = [];
            for i=1:length(stack)
                if strcmp(stack(i).file, mInitFilepath)
                    stackFrame = stack(i);
                    break;
                end
            end
        end
    end

    methods (Access = private, Hidden)
        function lineNumber = determineAppendixLineNumber(~, appFileContent, codeName)
            import appdesigner.internal.artifactgenerator.AppendixConstants;

            appendix = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
                appFileContent, AppendixConstants.AppLayoutIdentifier, AppendixConstants.AppRootElementName);

            patternToLocate = append(appdesigner.internal.artifactgenerator.AppendixConstants.ComponentNameAttribute, "='", codeName, "'");

            positionInAppendix = strfind(appendix, patternToLocate);

            appendixStartToFailure = extractBefore(appendix, positionInAppendix);

            withinAppendix = count(appendixStartToFailure, newline);

            indexOfAppendix = strfind(appFileContent, appendix);

            beforeAppendix = extractBefore(appFileContent, indexOfAppendix);

            linesBeforeAppendix = count(beforeAppendix, newline);

            lineNumber = linesBeforeAppendix + withinAppendix + 1;
        end

        function frame = createStackFrame(~, appFilepath, lineNumber)
            [~, ctorName, ~] = fileparts(appFilepath);

            frame = struct('file', char(appFilepath), 'name', char(ctorName), 'line', double(lineNumber));
        end
    end
end
