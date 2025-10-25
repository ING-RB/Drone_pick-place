classdef HTMLTestReportPlugin < matlab.unittest.plugins.TestReportPlugin & ...
                                matlab.unittest.internal.mixin.MainFileMixin
    % HTMLTestReportPlugin - Plugin to create a test report in '.html' format
    %
    %   A HTMLTestReportPlugin is constructed only with the
    %   TestReportPlugin.producingHTML method.
    %
    %   HTMLTestReportPlugin Properties:
    %       IncludeCommandWindowText  - Indicator if command window text is included in the report
    %       IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are included
    %       MainFile                  - Character vector that specifies the name of the main file only for the multi-file HTML report
    %
    %   Examples:
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.TestReportPlugin;
    %
    %       % Create a TestSuite array and a TestRunner
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       runner = TestRunner.withTextOutput;
    %
    %       % Add an TestReportPlugin to the TestRunner
    %       htmlOutput = 'report.html';
    %       plugin = TestReportPlugin.producingHTML(htmlOutput);
    %       runner.addPlugin(plugin);
    %
    %       % Run and view the report
    %       result = runner.run(suite);
    %       open(htmlOutput);
    %
    %   See Also:
    %       matlab.unittest.plugins.TestReportPlugin
    %       matlab.unittest.plugins.TestReportPlugin.producingHTML
    
    % Copyright 2016-2023 The MathWorks, Inc.
    properties(Hidden,SetAccess=immutable)
        ReportFolder
        StandaloneTestReport
    end
    
    methods(Access=?matlab.unittest.plugins.TestReportPlugin)
        function plugin = HTMLTestReportPlugin(varargin)
            if mod(nargin,2) == 1 % odd
                reportFileOrFolder = validateInput(varargin{1});
                allArgs = varargin(2:end);
            else % even
                reportFileOrFolder = tempname();
                allArgs = varargin;
            end
            [reportArgs, mainFileArgs, remainingArgs] = matlab.unittest.internal.resolveStandaloneReportInputs(reportFileOrFolder, allArgs{:});
            plugin = plugin@matlab.unittest.internal.mixin.MainFileMixin(mainFileArgs{:});
            plugin = plugin@matlab.unittest.plugins.TestReportPlugin(remainingArgs{:});
            plugin.ReportFolder = reportArgs.reportFolder;
            plugin.StandaloneTestReport = reportArgs.standaloneTestReport;
        end
    end
    
    methods(Hidden,Access=protected)
        function validateReportCanBeCreated(plugin)
            import matlab.unittest.internal.validateFolderWithFileCanBeCreated;
            validateFolderWithFileCanBeCreated(plugin.ReportFolder,plugin.MainFile);
        end
        
        function reportDocument = createReportDocument(plugin,testSessionData)
            import matlab.unittest.internal.plugins.testreport.HTMLTestReportDocument;
            reportDocument = HTMLTestReportDocument(plugin.ReportFolder,testSessionData,...
                plugin.StandaloneTestReport, 'MainFile',plugin.MainFile, 'Title',plugin.Title, ...
                'ProgressStream',plugin.ProgressStream, ...
                Clock_=plugin.Clock);
        end
    end
end

function fileOrFolder = validateInput(fileOrFolder)
matlab.automation.internal.mustBeTextScalar(fileOrFolder);
end
% LocalWords:  unittest plugins mynamespace
