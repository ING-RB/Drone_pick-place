classdef EventRecordFormatter < matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    methods (Abstract)
        str = getValidationEventReport(formatter, eventRecord)
        str = getExceptionEventReport(formatter, eventRecord)
        str = getLoggedDiagnosticEventReport(formatter, eventRecord)
        str = getQualificationEventReport(formatter, eventRecord)
    end
end

