classdef ResultsExtensionLiaison < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        ResultsFile (1,1) string        
        CodeIssues (1,1) codeIssues
        SourceRoot (1,1) string
    end

    properties (Constant)
        CodeIssuesVarName (1,1) string {mustBeValidVariableName} = "issues"
    end

    properties (Dependent, SetAccess = private)
        Extension
    end

    methods
        function liaison = ResultsExtensionLiaison(resultsFile, codeIssuesObj, sourceRoot)
            arguments
                resultsFile (1,1) string                
                codeIssuesObj (1,1) codeIssues
                sourceRoot (1,1) string
            end
            liaison.ResultsFile = resultsFile;            
            liaison.CodeIssues = codeIssuesObj;
            liaison.SourceRoot = sourceRoot;
        end

        function extension = get.Extension(liaison)
            [~, ~, extension] = fileparts(liaison.ResultsFile);
        end
    end
end