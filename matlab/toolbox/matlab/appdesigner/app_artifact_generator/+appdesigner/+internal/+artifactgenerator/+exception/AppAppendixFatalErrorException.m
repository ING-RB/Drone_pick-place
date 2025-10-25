classdef AppAppendixFatalErrorException < MException
    %APPAPPENDIXFATALERROREXCEPTION 

%   Copyright 2024 The MathWorks, Inc.

    properties (Access = private, Hidden)
        AppendixStack
    end

    methods
        function obj = AppAppendixFatalErrorException(filepath, parserError, fileContent)
            obj@MException('MATLABApp:appendixError', parserError.Message);

            lineNumber = obj.determineLineNumber(fileContent, parserError);

            obj.AppendixStack = obj.createStackToAppAppendix(lineNumber, filepath);
        end
    end

    methods (Access = protected)
        function stack = getStack(obj)
            stack = obj.AppendixStack;
        end
    end

    methods (Access = private, Hidden)
        function lineNumber = determineLineNumber(~, appFileContent, parserError)
            import appdesigner.internal.artifactgenerator.AppendixConstants;

            appendix = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
                appFileContent, AppendixConstants.AppLayoutIdentifier, AppendixConstants.AppRootElementName);

            xmlDocStart = strfind(appFileContent, appendix);

            linesBefore = extractBefore(appFileContent, xmlDocStart);

            newlinesBefore = count(linesBefore, newline);

            lineNumber = newlinesBefore + parserError.Location.LineNo;
        end

        function stackFrame = createStackToAppAppendix(~, lineNumber, filepath)
            [~, ctorName, ~] = fileparts(filepath);

            stackFrame = struct('file', char(filepath), 'name', char(ctorName), 'line', double(lineNumber));
        end
    end
end
