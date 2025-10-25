classdef PDFTestReportPlugin < matlab.unittest.plugins.TestReportPlugin & ...
                               matlab.unittest.internal.mixin.PageOrientationMixin
    % PDFTestReportPlugin - Plugin to create a test report in '.pdf' format
    %
    %   A PDFTestReportPlugin is constructed only with the
    %   TestReportPlugin.producingPDF method.
    %
    %   PDFTestReportPlugin Properties:
    %       IncludeCommandWindowText  - Indicator if command window text is included in the report
    %       IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are included
    %       PageOrientation           - Character vector that specifies the page orientation of the report
    %   
    %   PDF test reports are generated based on your system locale and the font
    %   families installed on your machine. When generating a report with a
    %   non-English locale, unless your machine has the 'Noto Sans CJK' font
    %   families installed, the report may have pound sign characters (#) in
    %   place of Chinese, Japanese, and Korean characters.
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
    %       pdfFile = 'MyTestReport.pdf';
    %       plugin = TestReportPlugin.producingPDF(pdfFile);
    %       runner.addPlugin(plugin);
    %
    %       result = runner.run(suite);
    %
    %       open(pdfFile);
    %
    %   See Also:
    %       matlab.unittest.plugins.TestReportPlugin
    %       matlab.unittest.plugins.TestReportPlugin.producingPDF
    
    % Copyright 2016-2023 The MathWorks, Inc.

    properties(Hidden,SetAccess=immutable)
        ReportFile
        RetainIntermediateFiles = false;
    end
    
    properties(Constant,Access=private)
        ArgumentParser = createArgumentParser();
    end
    
    methods(Access=?matlab.unittest.plugins.TestReportPlugin)
        function plugin = PDFTestReportPlugin(varargin)
            import matlab.unittest.internal.newFileResolver;
            import matlab.unittest.plugins.testreport.PDFTestReportPlugin;
            import matlab.unittest.internal.extractParameterArguments;
            
            if mod(nargin,2) == 1 % odd
                reportFile = newFileResolver(varargin{1},'.pdf');
                allArgs = varargin(2:end);
            else % even
                reportFile = [tempname() '.pdf'];
                allArgs = varargin;
            end
            
            [retainIntermediateFilesArgs,remainingArgs] = extractParameterArguments(...
                'RetainIntermediateFiles',allArgs{:});
            parser = PDFTestReportPlugin.ArgumentParser;
            parser.parse(retainIntermediateFilesArgs{:});
            
            [pageOrientationArgs,remainingArgs] = extractParameterArguments('PageOrientation',remainingArgs{:});
            plugin = plugin@matlab.unittest.internal.mixin.PageOrientationMixin(pageOrientationArgs{:});
            
            plugin = plugin@matlab.unittest.plugins.TestReportPlugin(remainingArgs{:});
            
            plugin.ReportFile = reportFile;
            plugin.RetainIntermediateFiles = parser.Results.RetainIntermediateFiles;
        end
    end
    
    methods(Hidden,Access=protected)
        function validateReportCanBeCreated(plugin)
            matlab.unittest.internal.validateFileCanBeCreated(plugin.ReportFile);
        end
        
        function reportDocument = createReportDocument(plugin,testSessionData)
            import matlab.unittest.internal.plugins.testreport.PDFTestReportDocument;
            reportDocument = PDFTestReportDocument(plugin.ReportFile,testSessionData,...
                'PageOrientation',plugin.PageOrientation, 'Title',plugin.Title, ...
                'ProgressStream',plugin.ProgressStream, 'RetainIntermediateFiles',plugin.RetainIntermediateFiles, ...
                Clock_=plugin.Clock);
        end
    end
end


function parser = createArgumentParser()
parser = matlab.unittest.internal.strictInputParser;
parser.addParameter('RetainIntermediateFiles', false, ...
    @(x) validateattributes(x,{'logical'},{'scalar'},'','RetainIntermediateFiles'));
end

% LocalWords:  Noto CJK unittest plugins mynamespace
