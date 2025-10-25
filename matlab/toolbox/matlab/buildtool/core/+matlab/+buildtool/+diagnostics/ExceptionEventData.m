classdef (Hidden) ExceptionEventData < event.EventData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % This class is similar to its counterpart in the testing frameworks. For
    % more information, see the help for 
    % matlab.unittest.qualifications.ExceptionEventData.
    
    % Copyright 2021-2022 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        % Exception - Unexpected exception caught
        Exception MException {mustBeScalarOrEmpty}
    end
    
    methods (Hidden)
        function data = ExceptionEventData(exception)
            arguments
                exception (1,1) MException
            end
            data.Exception = exception;
        end
    end
end

