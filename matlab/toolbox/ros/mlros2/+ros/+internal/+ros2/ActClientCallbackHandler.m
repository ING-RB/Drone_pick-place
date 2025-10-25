classdef ActClientCallbackHandler < handle
%This class is for internal use only. It may be removed in the future.

%ActClientCallbackHandler is helper to process the callbacks. This is the
%   entry gate-way for the callbacks from action-client which comes
%   asynchronously from back-end.

%   Copyright 2022 The MathWorks, Inc.

    properties (Transient, Access = ?ros.internal.mixin.InternalAccess)
        ActClientWeakHandle
    end

    methods
        function onGoalResponseCallbackFcn(obj, msg, info)
            % msg contains goalAccepted, goalUUID, goalIndex
            % info contains handle
            processGoalResponseCallback(obj.ActClientWeakHandle.get, msg, info);
        end

        function onFeedbackReceivedCallbackFcn(obj, msg, info)
            % msg contains Feedback, goalUUID, goalIndex
            % info contains handle
            processFeedbackCallback(obj.ActClientWeakHandle.get, msg, info);
        end

        function onResultReceivedCallbackFcn(obj, msg, info, state)
            % msg contains Result, goalUUID, goalIndex, resultStatus
            % info contains handle
            processResultCallback(obj.ActClientWeakHandle.get, msg, info, state);
        end

        function onCancelCallbackFcn(obj, msg, info)
            % msg.goalIndex
            % msg.cancelResponse.return_code - 0/1/2/3
            %   0 successfully cancelled the goal
            %   1 error_rejected
            %   2 error_unknown_goal_id
            %   3 error_goal_terminated
            % info contains handle
            processCancelCallback(obj.ActClientWeakHandle.get, msg, info);
        end

        function onCancelAllCallbackFcn(obj, msg, info)
            % msg.return_code - 0/1/2/3
            %   0 successfully cancelled the goal
            %   1 error_rejected
            %   2 error_unknown_goal_id
            %   3 error_goal_terminated
            % info contains handle
            processCancelAllCallback(obj.ActClientWeakHandle.get, msg, info);
        end

        function onCancelBeforeCallbackFcn(obj, msg, info)
            processCancelBeforeCallbackFcn(obj.ActClientWeakHandle.get, msg, info);
        end
    end
end