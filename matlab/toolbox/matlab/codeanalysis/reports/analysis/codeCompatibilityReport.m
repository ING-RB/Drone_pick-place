function codeCompatibilityReport(varargin)
%CODECOMPATIBILITYREPORT Creates and opens a code compatibility report.
%
%   codeCompatibilityReport creates a code compatibility report for the
%   current working folder and subfolders.
%
%   codeCompatibilityReport(names) creates a code compatibility report for
%   files or folders specified by names, where names is a string scalar,
%   character vector, string array, or cell array of character vectors. The
%   filename must be a valid MATLAB code or App file (*.m, *.mlx, or *.mlapp).
%
%   codeCompatibilityReport(..., 'IncludeSubfolders', false) excludes
%   subfolders from the code compatibility analysis. Use this syntax with
%   any of the arguments in previous syntaxes.
%
%   codeCompatibilityReport(CCA) displays a report for CodeCompatibilityAnalysis
%   object CCA.
%
%   Example:
%   codeCompatibilityReport
%   codeCompatibilityReport(CCA)
%
%   See also analyzeCodeCompatibility, CodeCompatibilityAnalysis

%   Copyright 2017-2023 The MathWorks, Inc.

    try
        validatedAnalysisResults = @(x)(isa(x, 'CodeCompatibilityAnalysis'));

        if ~any(cellfun(validatedAnalysisResults, varargin))
            % Input does not contain code compatibility result
            launchCodeAnalyzerReport(varargin{:});
        elseif isscalar(varargin) && isscalar(varargin{1})
            % There is only one code compatibility result, and it is scalar
            obj = matlab.codeanalyzerreport.internal.Server(varargin{:});
            launchReport(obj);
        elseif isscalar(varargin)
            % There is only one code compatibility result, but it is not scalar
            error(message('codeanalysis:reports:ccrAnalysis:ScalarObject'));
        else
            % There are multiple inputs, at least one of them is code compatibility result
            error(message('codeanalysis:reports:ccrAnalysis:TooManyInputsWithObject'));
        end
    catch ex
        throw(ex);
    end
end

% Use this location function to
% 1. validate the input of codeCompatibilityReport
% 2. set the input items to be pwd if not provided.
%    In code analyzer report, when item is not provided, it will launch the
%    app version.
%    In code compatibility report, when the item is not provided, it will
%    launch the report with pwd.
function launchCodeAnalyzerReport(items, options)
    arguments
        items {mustBeNonzeroLengthText} = pwd
        options.IncludeSubfolders logical = true
    end
    configFile = matlab.internal.codecompatibilityreport.getConfigFile();
    obj = matlab.codeanalyzerreport.internal.Server.create(items, ...
        IncludeSubfolders=options.IncludeSubfolders, ...
        CodeAnalyzerConfiguration=configFile, ...
        IsCompatibilityReport=true);
    launchReport(obj);
end
