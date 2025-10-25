classdef DOCXTestReportDocument < matlab.unittest.internal.dom.DOCXReportDocument
    % This class is undocumented and may change in a future release.
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    properties(GetAccess=private, SetAccess=immutable)
        TestSessionData
    end
    
    methods
        function reportDoc = DOCXTestReportDocument(varargin)
            import matlab.unittest.internal.plugins.testreport.TestReportData;
            
            narginchk(1,Inf);
            
            if mod(nargin,2) == 1 % odd
                reportFile = [tempname() '.docx'];
                testSessionData = varargin{1};
                allArgs = varargin(2:end);
            else % even
                reportFile = varargin{1};
                testSessionData = varargin{2};
                allArgs = varargin(3:end);
            end
            
            validateattributes(testSessionData,{'matlab.unittest.internal.TestSessionData'},{'scalar'});
            
            reportDoc = reportDoc@matlab.unittest.internal.dom.DOCXReportDocument(reportFile,allArgs{:});
            
            reportDoc.ReportDocumentParts = [...
                matlab.unittest.internal.plugins.testreport.CoverPageSummaryPart(reportDoc.Clock, reportDoc.Title, reportDoc.PageOrientation),...
                matlab.unittest.internal.plugins.testreport.FailureSummaryPart(),...
                matlab.unittest.internal.plugins.testreport.FilterSummaryPart(),...
                matlab.unittest.internal.plugins.testreport.SuiteOverviewPart(),...
                reportDoc.createServiceLocatedParts(testSessionData),...
                matlab.unittest.internal.plugins.testreport.SuiteDetailsPart(),...
                matlab.unittest.internal.plugins.testreport.CommandWindowTextPart()];
            
            reportDoc.TestSessionData = testSessionData;
        end
    end
    
    methods(Access=protected)
        function reportData = createReportData(reportDoc)
            import matlab.unittest.internal.plugins.testreport.TestReportData;
            reportData = TestReportData('docx',reportDoc.TestSessionData);
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

% LocalWords:  unittest dom testreport serv
