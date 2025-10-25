classdef HTMLTestReportDocument < matlab.unittest.internal.dom.HTMLReportDocument
    % This class is undocumented and may change in a future release.
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    properties(GetAccess=private, SetAccess=immutable)
        TestSessionData
    end
    
    methods
        function reportDoc = HTMLTestReportDocument(varargin)

            narginchk(1,Inf);
            if nargin == 1
                reportFolder = tempname();
                testSessionData = varargin{1};
                standaloneTestReport = false;
                allArgs = varargin(2:end);
            elseif mod(nargin,2) == 1 % odd
                reportFolder = varargin{1};
                testSessionData = varargin{2};
                standaloneTestReport = varargin{3};
                allArgs = varargin(4:end);
            else % even
                reportFolder = tempname();
                testSessionData = varargin{1};
                standaloneTestReport = varargin{2};
                allArgs = varargin(3:end);
            end

            validateattributes(testSessionData,{'matlab.unittest.internal.TestSessionData'},{'scalar'});
            
            reportDoc = reportDoc@matlab.unittest.internal.dom.HTMLReportDocument(reportFolder, standaloneTestReport, allArgs{:});
            
            reportDoc.ReportDocumentParts = [...
                matlab.unittest.internal.plugins.testreport.CoverPageSummaryPart(reportDoc.Clock, reportDoc.Title),...
                matlab.unittest.internal.plugins.testreport.FailureSummaryPart(),...
                matlab.unittest.internal.plugins.testreport.FilterSummaryPart(),...
                matlab.unittest.internal.plugins.testreport.SuiteOverviewPart(),... 
                reportDoc.createServiceLocatedParts(testSessionData),...
                matlab.unittest.internal.plugins.testreport.SuiteDetailsPart(),...
                matlab.unittest.internal.plugins.testreport.CommandWindowTextPart(),...
                matlab.unittest.internal.plugins.testreport.JavascriptAddonPart()];
            
            reportDoc.TestSessionData = testSessionData;            
        end
    end
    
    methods(Access=protected)
        function reportData = createReportData(reportDoc)
            import matlab.unittest.internal.plugins.testreport.TestReportData;
            if reportDoc.StandaloneTestReport
                reportData = TestReportData('html-file',reportDoc.TestSessionData);
            else
                reportData = TestReportData('html',reportDoc.TestSessionData);
            end
        end
    end
    
    methods (Access = private)
        function parts = createServiceLocatedParts(~, testSessionData)
            import matlab.unittest.internal.plugins.testreport.BlankPart;
            import matlab.unittest.internal.services.plugins.testreport.TestReportDocumentPartLiaison;
            
            parts = BlankPart;
            partServices = locateAdditionalTestReportPartServices;
            if ~isempty(partServices)
                partLiaison = TestReportDocumentPartLiaison(testSessionData);
                partServices.fulfill(partLiaison);
                if ~isempty(partLiaison.Parts)
                   parts = partLiaison.Parts; 
                end
            end            
        end
    end
end

function services = locateAdditionalTestReportPartServices()
import matlab.automation.internal.services.ServiceLocator;
import matlab.unittest.internal.services.ServiceFactory;

namespace = meta.package.fromName("matlab.unittest.internal.services.plugins.testreport");
servLocator = ServiceLocator.forNamespace(namespace);
interface = ?matlab.unittest.internal.services.plugins.testreport.TestReportDocumentService;
servClassesWithInterface = servLocator.locate(interface);

servFactory = ServiceFactory;
services = servFactory.create(servClassesWithInterface);
end

% LocalWords:  unittest dom testreport Addon serv
