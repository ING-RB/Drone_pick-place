classdef EventRecordFormatter
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2018 The MathWorks, Inc.
    methods(Abstract)
        str = getExceptionEventReport(formatter, eventRecord);
        str = getQualificationEventReport(formatter, eventRecord);
        str = getLoggedDiagnosticEventReport(formatter, eventRecord);
    end
end

% LocalWords:  formatter
