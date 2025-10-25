function codeCompatibilityAnalyzer
%CODECOMPATIBILITYANALYZER Allows selecting a folder and opens a code compatibility report.
%
%   codeCompatibilityAnalyzer creates a code compatibility report for the
%   selected folder and its subfolders.
%

%   Copyright 2021-2023 The MathWorks, Inc.
    configFile = matlab.internal.codecompatibilityreport.getConfigFile();
    obj = matlab.codeanalyzerreport.internal.Server.create(CodeAnalyzerConfiguration=configFile, IsCompatibilityReport=true);
    launchReport(obj);
end
