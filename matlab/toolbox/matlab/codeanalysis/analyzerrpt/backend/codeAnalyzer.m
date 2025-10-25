function codeAnalyzer(varargin)
%codeAnalyzer opens a code analyzer report to display issues found in code
%
%   codeAnalyzer(names) opens a code analyzer report for files or folders
%   specified by names, where names is a string array, character vector,
%   or cell array of character vectors. The files to analyze must
%   be valid MATLAB code or app files (*.m, *.mlx, or *.mlapp).
%
%   codeAnalyzer(names, IncludeSubfolders = false) excludes
%   subfolders from the analysis.
%
%   codeAnalyzer(issues) displays a report for codeIssues object.
%
%   Example:
%   codeAnalyzer
%   codeAnalyzer(pwd)
%   codeAnalyzer(issues)
%
%   See also codeIssues

%   Copyright 2021-2022 The MathWorks, Inc.


    try
        if ~any(cellfun(@(x)(isa(x, 'codeIssues')), varargin))
            % Input does not contains code issues result
            obj = matlab.codeanalyzerreport.internal.Server.create(varargin{:});
            launchReport(obj);
        else
            % Input is code issues result.
            obj = matlab.codeanalyzerreport.internal.Server(varargin{:});
            launchReport(obj);
        end
    catch e
        throw(e);
    end
end
