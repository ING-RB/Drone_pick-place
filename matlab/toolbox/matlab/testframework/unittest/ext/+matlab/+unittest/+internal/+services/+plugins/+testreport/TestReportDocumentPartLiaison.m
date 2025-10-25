classdef TestReportDocumentPartLiaison <  handle
    
    properties
        Parts = matlab.unittest.internal.dom.ReportDocumentPart.empty(1,0);
    end
    
    properties (SetAccess = immutable)
        TestSessionData
    end
    
    methods
        function liaison = TestReportDocumentPartLiaison(testSessionData)
            liaison.TestSessionData = testSessionData;
        end
    end
end