classdef (Hidden) ValidationFailure
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % ValidationFailure - Validation failure information

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % Location - Location of failure
        Location matlab.buildtool.validations.ValidationLocation {mustBeScalarOrEmpty}

        % Message - Message about failure
        Message message {mustBeScalarOrEmpty}
    end

    methods (Hidden)
        function failure = ValidationFailure(location, msg)
            arguments
                location (1,1) matlab.buildtool.validations.ValidationLocation
                msg (1,1) message
            end
            failure.Location = location;
            failure.Message = msg;
        end
    end
end
