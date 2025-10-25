classdef QualificationDelegate < matlab.mixin.Copyable
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties(Abstract, Constant, Access = protected)
        Type
    end

    methods(Abstract)
        doFail(delegate)
    end

    methods(Sealed)
        function fail(delegate, notificationData, actual, diag)
            import matlab.buildtool.internal.qualifications.QualificationEventData;

            stack = dbstack("-completenames");
            eventData = QualificationEventData(stack, actual, diag);
            notificationData.NotifyFailed(eventData);
            notificationData.Qualifiable.invokePostFailureEventCallbacks(struct("Type", string(eventData.EventName)));
            delegate.doFail();
        end
    end

    methods
        function qualifyTrue(delegate, notificationData, actual, diag)
            if ~actual
                delegate.fail(notificationData, actual, diag);
            end
        end
    end
end