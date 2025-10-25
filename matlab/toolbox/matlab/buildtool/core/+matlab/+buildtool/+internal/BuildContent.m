classdef BuildContent < handle & matlab.mixin.Copyable
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    events (NotifyAccess = private)
        % ValidationFailed - Event triggered when validation fails
        ValidationFailed

        % ExceptionThrown - Event triggered when an exception is thrown
        ExceptionThrown
    end
    
    methods (Access = ?matlab.buildtool.BuildRunner)
        function notifyValidationFailedEvent_(content, failure)
            arguments
                content (1,1) matlab.buildtool.internal.BuildContent
                failure (1,1) matlab.buildtool.validations.ValidationFailure
            end

            import matlab.buildtool.validations.ValidationEventData;

            eventData = ValidationEventData(failure);
            content.notify("ValidationFailed", eventData);
        end

        function notifyExceptionThrownEvent_(content, exception)
            arguments
                content (1,1) matlab.buildtool.internal.BuildContent
                exception (1,1) MException
            end
            
            import matlab.buildtool.diagnostics.ExceptionEventData;
            
            eventData = ExceptionEventData(exception);
            content.notify("ExceptionThrown", eventData);
        end
    end
end

