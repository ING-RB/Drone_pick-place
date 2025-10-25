function [analysis] = analyzeCodeCompatibility(names, options)
%analyzeCodeCompatibility Creates code compatibility analysis results.
%
%   RESULTS = analyzeCodeCompatibility creates code compatibility analysis
%   results for current working folder and subfolders, and returns the
%   result as a CodeCompatibilityAnalysis object.
%
%   RESULTS = analyzeCodeCompatibility(names), analyzes the files or folders
%   specified by names, where names is a string scalar, character vector,
%   string array, or cell array of character vectors. The filename must be
%   a valid MATLAB code or App file (*.m, *.mlx, or *.mlapp).
%
%   RESULTS = analyzeCodeCompatibility(..., 'IncludeSubfolders', false)
%   excludes subfolders from the code compatibility analysis. Use this
%   syntax with any of the arguments in previous syntaxes.
%
%   Example:
%
%   result = analyzeCodeCompatibility
%   result =
%     CodeCompatibilityAnalysis with properties:
%
%                  Date: 24-Jan-2017 11:43:13
%         MATLABVersion: "R2017b"
%                 Files: [3x1 string]
%       ChecksPerformed: [291x6 table]
%       Recommendations: [16x7 table]
%
%   See also CodeCompatibilityAnalysis, codeCompatibilityReport

%   Copyright 2017-2022 The MathWorks, Inc.

% Setup input argument constraints and input parser
% When we have an even number of input arguments, input inputParser can't
% identify whether the first input argument is a file list or the start of
% a name/value pair.
% Since there is only one optional input argument, we only get an even
% number of arguments if the file list is not provided. We can therefore
% safely prepend the default value of file list to the input argument list.
    arguments
        names {mustBeNonzeroLengthText} = pwd;
        options.IncludeSubfolders (1,1) logical = true;
    end

    configFile = matlab.internal.codecompatibilityreport.getConfigFile();
    issues = codeIssues(names, ...
        IncludeSubfolders=options.IncludeSubfolders, ...
        CodeAnalyzerConfiguration=configFile);

    analysis = CodeCompatibilityAnalysis.create(issues);
end
