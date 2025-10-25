classdef TestDetailsPartLiaison < handle
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties
       Parts = matlab.unittest.internal.dom.ReportDocumentPart.empty(1,0);         
    end
    
    properties (SetAccess = immutable)
       ReportData 
       TestIndex
    end
    
    methods
        function liaison = TestDetailsPartLiaison(testIndex, testReportData)
            liaison.TestIndex  = testIndex;
            liaison.ReportData = testReportData;
        end
    end
end