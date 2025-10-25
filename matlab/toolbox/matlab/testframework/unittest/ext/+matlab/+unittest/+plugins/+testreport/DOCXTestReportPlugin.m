classdef DOCXTestReportPlugin < matlab.unittest.plugins.TestReportPlugin & ...
                                matlab.unittest.internal.mixin.PageOrientationMixin
    % DOCXTestReportPlugin - Plugin to create a test report in '.docx' format
    %
    %   A DOCXTestReportPlugin is constructed only with the
    %   TestReportPlugin.producingDOCX method.
    %
    %   DOCXTestReportPlugin Properties:
    %       IncludeCommandWindowText  - Indicator if command window text is included in the report
    %       IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are included
    %       PageOrientation           - Character vector that specifies the page orientation of the report
    %
    %   Examples:
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.TestReportPlugin;
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       % Create a test runner
    %       runner = TestRunner.withTextOutput;
    %
    %       % Add an TestReportPlugin to the TestRunner
    %       docxFile = 'MyTestReport.docx';
    %       plugin = TestReportPlugin.producingDOCX(docxFile);
    %       runner.addPlugin(plugin);
    %
    %       result = runner.run(suite);
    %
    %       open(docxFile);
    %
    %   See Also:
    %       matlab.unittest.plugins.TestReportPlugin
    %       matlab.unittest.plugins.TestReportPlugin.producingDOCX
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties(Hidden,SetAccess=immutable)
        ReportFile
    end
    
    methods(Access=?matlab.unittest.plugins.TestReportPlugin)
        function plugin = DOCXTestReportPlugin(varargin)
            import matlab.unittest.internal.newFileResolver;
            import matlab.unittest.internal.extractParameterArguments;
            
            if mod(nargin,2) == 1 % odd
                reportFile = newFileResolver(varargin{1},'.docx');
                allArgs = varargin(2:end);
            else % even
                reportFile = [tempname() '.docx'];
                allArgs = varargin;
            end
            
            [pageOrientationArgs,remainingArgs] = extractParameterArguments('PageOrientation',allArgs{:});
            plugin = plugin@matlab.unittest.internal.mixin.PageOrientationMixin(pageOrientationArgs{:});

            plugin = plugin@matlab.unittest.plugins.TestReportPlugin(remainingArgs{:});
            
            plugin.ReportFile = reportFile;
        end
    end
    
    methods(Hidden,Access=protected)
        function validateReportCanBeCreated(plugin)
            matlab.unittest.internal.validateFileCanBeCreated(plugin.ReportFile);
        end
        
        function reportDocument = createReportDocument(plugin,testSessionData)
            import matlab.unittest.internal.plugins.testreport.DOCXTestReportDocument;
            reportDocument = DOCXTestReportDocument(plugin.ReportFile,testSessionData,...
                'PageOrientation',plugin.PageOrientation, 'Title',plugin.Title, ...
                'ProgressStream',plugin.ProgressStream, ...
                Clock_=plugin.Clock);
        end
    end
end

% LocalWords:  unittest plugins mynamespace
