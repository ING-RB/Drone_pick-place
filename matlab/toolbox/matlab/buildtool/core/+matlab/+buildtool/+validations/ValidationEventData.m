classdef (Hidden) ValidationEventData < event.EventData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % ValidationEventData - Event data for validation event listeners 
    
    % Copyright 2022-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        % Failure - Validation failure
        Failure matlab.buildtool.validations.ValidationFailure {mustBeScalarOrEmpty}
    end
    
    methods (Hidden)
        function data = ValidationEventData(failure)
            arguments
                failure matlab.buildtool.validations.ValidationFailure {mustBeScalarOrEmpty} = matlab.buildtool.validations.ValidationFailure.empty()
            end
            data.Failure = failure;
        end
    end
end
