classdef(Abstract,Hidden,HandleCompatible) DiagnosticDataMixin
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2016-2020 The MathWorks, Inc.
    
    properties (Hidden, SetAccess={?matlab.unittest.TestRunner})
        DiagnosticData;
    end
    
    methods
        function data = DiagnosticDataMixin
            data.DiagnosticData = matlab.unittest.diagnostics.DiagnosticData.DefaultInstance;
        end
    end
end
