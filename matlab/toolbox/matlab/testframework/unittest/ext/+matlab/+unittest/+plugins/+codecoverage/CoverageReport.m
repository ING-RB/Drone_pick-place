classdef CoverageReport < matlab.unittest.plugins.codecoverage.CoverageFormat ...
        & matlab.unittest.internal.mixin.MainFileMixin
    % CoverageReport - A format to create a code coverage report.
    %
    %   To display the code coverage metrics in the MATLAB browser, use an
    %   instance of the CoverageReport class with the CodeCoveragePlugin.
    %
    %   CoverageReport methods:
    %       CoverageReport - Class constructor
    %
    %   CoverageReport properties:
    %       MainFile - Character vector that specifies the name of the main file for the HTML report
    %
    %   Example:
    %
    %       import matlab.unittest.plugins.CodeCoveragePlugin;
    %       import matlab.unittest.plugins.codecoverage.CoverageReport;
    %
    %       % Construct the CoverageReport format
    %       reportFolder = 'CoverageReportRoot';
    %       format = CoverageReport(reportFolder);
    %
    %       % Construct a CodeCoveragePlugin with the CoverageReport format
    %       plugin = CodeCoveragePlugin.forFile('C:\projects\myproj\foo.m',...
    %           'Producing',format);
    %
    %   See also: matlab.unittest.plugins.CodeCoveragePlugin
    
    % Copyright 2017-2024 The MathWorks, Inc.
    
    properties (Hidden,SetAccess=immutable)
        TargetFolder;
        DocumentTitle
    end

    properties (Hidden, Dependent)
        Filename;
    end
    
    methods
        function coverageReport = CoverageReport(reportFolder,optionalNameValueArgs)
            % CoverageReport - Construct a CoverageReport format.
            %
            %   FORMAT = CoverageReport() constructs a CoverageReport format. 
            %   When used with the CodeCoveragePlugin, it produces an HTML file
            %   in a temporary folder that contains the code coverage report.
            %
            %   FORMAT = CoverageReport(REPORTFOLDER) constructs a CoverageReport
            %   format. When used with the CodeCoveragePlugin, it produces an HTML file
            %   containing the code coverage report in the folder specified by 
            %   REPORTFOLDER. Every time the report is generated, the contents inside 
            %   REPORTFOLDER are overwritten.
            %
            %   FORMAT = CoverageReport(...,'MainFile',MAINFILENAME) constructs a
            %   CoverageReport where MAINFILENAME is the name of the main HTML 
            %   file containing the code coverage report.
            %           
            %   FORMAT = CoverageReport(...,'DocumentTitle',TITLE)
            %   constructs a CoverageReport where TITLE is the title of the
            %   HTML document containing the code coverage report.
            arguments
                reportFolder (1,:) {matlab.unittest.internal.mustBeTextScalar} =  tempname();
                optionalNameValueArgs.MainFile (1,:) {mustBeTextScalar} = 'index.html';
                optionalNameValueArgs.DocumentTitle (1,:) string {mustBeTextScalar, mustBeNonmissing} = "";
            end
            import matlab.unittest.internal.parentFolderResolver;
           
            mainFileArgs = cellstr(["MainFile", optionalNameValueArgs.MainFile]);
            coverageReport = coverageReport@matlab.unittest.internal.mixin.MainFileMixin(mainFileArgs{:});            
            coverageReport.TargetFolder = parentFolderResolver(reportFolder);
            coverageReport.DocumentTitle = optionalNameValueArgs.DocumentTitle;
        end
        
        function fileName = get.Filename(coverageReport)
            fileName = fullfile(coverageReport.TargetFolder, coverageReport.MainFile);
        end
    end
    
    methods (Hidden, Access = {?matlab.unittest.internal.mixin.CoverageFormatMixin,...
            ?matlab.unittest.plugins.codecoverage.CoverageFormat})
        
        function generateCoverageReport(coverageReport,~,coverageResult,msgID, unappliedFilters)
            htmlReport = matlab.unittest.internal.coverage.generateHTMLReportInternal(coverageResult, coverageReport.TargetFolder,...
                'MainFile', coverageReport.MainFile, 'DocumentTitle', coverageReport.DocumentTitle, 'UnappliedFilters', unappliedFilters);
            urltoLoad = coverageReport.getReportURL();
            createAndDisplayReportLink(htmlReport, urltoLoad, msgID);
        end
    end
    
    methods (Hidden)
        function validateReportCanBeCreated(coverageReport)
            import matlab.unittest.internal.validateFolderWithFileCanBeCreated;
            validateFolderWithFileCanBeCreated(coverageReport.TargetFolder,coverageReport.MainFile);
        end

        function urltoLoad = getReportURL(coverageReport)
            connector.ensureServiceOn();
            contentUrlPath = connector.addStaticContentOnPath("report" + matlab.lang.internal.uuid, fileparts(coverageReport.Filename));
            rawURL = connector.getUrl([contentUrlPath, '/', coverageReport.MainFile]);
            U = matlab.net.URI(rawURL,'Filterable','true');
            urltoLoad = char(U);
        end
    end

    methods (Static, Hidden)
        function files = listSupportingFiles()
            files = matlab.unittest.internal.coverage.CoverageReportDataPublisher.listPublishedFiles();
        end
    end
end

function createAndDisplayReportLink(htmlReportFilename, urltoLoad, msgID)
import matlab.unittest.internal.diagnostics.CommandHyperlinkableString;
import matlab.unittest.internal.plugins.LinePrinter;
import matlab.unittest.internal.diagnostics.MessageString;

openCmd = generateOpenCommand(urltoLoad);
reportFileLinkString = CommandHyperlinkableString(htmlReportFilename, openCmd);
printer = LinePrinter;
printer.printLine(MessageString(msgID,reportFileLinkString));
end

function command = generateOpenCommand(report)
command = sprintf('web(''%s'',''-noaddressbox'',''-new'')',strrep(report,'''',''''''));
end
