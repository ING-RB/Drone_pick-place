classdef CoverPageSummaryPart < matlab.unittest.internal.dom.ReportDocumentPart
    %This class is undocumented and may change in a future release.
    
    % Copyright 2016-2023 The MathWorks, Inc.

    properties(SetAccess=immutable)
        Clock;
        PageOrientation;
        Title;
    end
    
    properties(Access=private)
        NumberOfTests = [];
        TotalTestingTime = [];
        AllFiltered = [];
        AnyFailed = [];
        AnyUnreached = [];
        CoverPageTopMarginPart = [];
        PieChartSummaryPart = [];
    end
    
    properties(Constant,Access=private)
        Catalog = matlab.internal.Catalog('MATLAB:unittest:TestReportDocument');
    end
    
    methods
        function docPart = CoverPageSummaryPart(clock, title, pageOrientation)
            arguments
                clock = @datetime;
                title = '';
                pageOrientation = '';
            end
            docPart.Clock = clock;
            docPart.Title = title;
            docPart.PageOrientation = pageOrientation;
        end
    end
    
    methods(Access=protected)
        function delegateDocPart = createDelegateDocumentPart(~,testReportData)
            delegateDocPart = testReportData.createDelegateDocumentPartFromName('CoverPageSummaryPart');
        end
        
        function setupPart(docPart,testReportData)
            import matlab.unittest.internal.plugins.testreport.BlankPart;
            import matlab.unittest.internal.plugins.testreport.CoverPageTopMarginPart;
            import matlab.unittest.internal.plugins.testreport.PieChartSummaryPart;
            import matlab.unittest.internal.plugins.testreport.PieChartSummaryAlternativePart;
            import matlab.unittest.internal.plugins.supportsFigurePrinting;
            
            docPart.NumberOfTests = testReportData.TestSessionData.NumberOfTests;
            docPart.TotalTestingTime = sum([testReportData.TestSessionData.TestResults.Duration]);
            
            docPart.AllFiltered = all(testReportData.TestSessionData.FilteredMask);
            docPart.AnyFailed = any(testReportData.TestSessionData.FailedMask);
            docPart.AnyUnreached = any(testReportData.TestSessionData.UnreachedMask);
            
            docPart.CoverPageTopMarginPart = CoverPageTopMarginPart(docPart.PageOrientation); %#ok<CPROPLC>
            docPart.CoverPageTopMarginPart.setup(testReportData);
            
            if docPart.NumberOfTests == 0
                docPart.PieChartSummaryPart = BlankPart();
            elseif supportsFigurePrinting()
                docPart.PieChartSummaryPart = PieChartSummaryPart(); %#ok<CPROPLC>
            else
                docPart.PieChartSummaryPart = PieChartSummaryAlternativePart();
            end
            docPart.PieChartSummaryPart.setup(testReportData);
        end
        
        function teardownPart(docPart)
            docPart.NumberOfTests = [];
            docPart.TotalTestingTime = [];
            docPart.AllFiltered = [];
            docPart.AnyFailed = [];
            docPart.AnyUnreached = [];
            docPart.CoverPageTopMarginPart = [];
            docPart.PieChartSummaryPart = [];
        end
    end
    
    methods(Hidden) % Fill template holes ---------------------------------
        function fillCoverPageTopMarginPart(docPart)
            docPart.appendDocParts(docPart.CoverPageTopMarginPart);
        end
        
        function fillTitle(docPart)
            docPart.appendText(docPart.Title);
        end
        
        function fillTimestampLabel(docPart)
            docPart.appendLabelFromKey('TimestampLabel');
        end
        
        function fillTimestamp(docPart)
            currentTime = docPart.Clock();
            docPart.appendText(char(currentTime));
        end
        
        function fillHostLabel(docPart)
            docPart.appendLabelFromKey('HostLabel');
        end
        
        function fillHost(docPart)
            host = matlab.unittest.internal.getHostname();
            docPart.appendText(host);
        end
        
        function fillPlatformLabel(docPart)
            docPart.appendLabelFromKey('PlatformLabel');
        end
        
        function fillPlatform(docPart)
            docPart.appendText(computer('arch'));
        end
        
        function fillMATLABVersionLabel(docPart)
            docPart.appendLabelFromKey('MATLABVersionLabel');
        end
        
        function fillMATLABVersion(docPart)
            docPart.appendText(version());
        end
        
        function fillNumberOfTestsLabel(docPart)
            docPart.appendLabelFromKey('NumberOfTestsLabel');
        end
        
        function fillNumberOfTests(docPart)
            numOfTestsStr = sprintf('%u',docPart.NumberOfTests);
            docPart.appendText(numOfTestsStr);
        end
        
        function fillTestingTimeLabel(docPart)
            docPart.appendLabelFromKey('TestingTimeLabel');
        end
        
        function fillTestingTime(docPart)
            testingTimeStr = docPart.Catalog.getString('TimeInSeconds',...
                sprintf('%.4f',docPart.TotalTestingTime));
            docPart.appendText(testingTimeStr);
        end
        
        function fillOverallResultLabel(docPart)
            docPart.appendLabelFromKey('OverallResultLabel');
        end
        
        function fillOverallResult(docPart)
            if docPart.NumberOfTests == 0
                overallResultText = '--';
            elseif docPart.AllFiltered
                overallResultText = docPart.Catalog.getString('AllTestsFiltered');
            elseif docPart.AnyFailed
                overallResultText = upper(docPart.Catalog.getString('Failed'));
            elseif docPart.AnyUnreached
                overallResultText = docPart.Catalog.getString('TestRunAborted');
            else
                overallResultText = upper(docPart.Catalog.getString('Passed'));
            end
            docPart.appendText(overallResultText);
        end
        
        function fillPieChartSummaryPart(docPart)
            docPart.appendDocParts(docPart.PieChartSummaryPart);
        end
    end
    
    methods(Access=private)
        function appendLabelFromKey(docPart,msgIDKey)
            docPart.appendText(docPart.Catalog.getString(msgIDKey));
        end
    end
end

% LocalWords:  unittest dom CPROPLC
