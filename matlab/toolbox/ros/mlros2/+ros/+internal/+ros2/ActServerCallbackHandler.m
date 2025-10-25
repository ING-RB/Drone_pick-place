classdef ActServerCallbackHandler < handle
%

%   Copyright 2023 The MathWorks, Inc.

    properties (Transient, Access = ?ros.internal.mixin.InternalAccess)
        ActServerWeakHandle
    end

    methods
        function onHandleGoalReceivedCB(obj,msg,info)
            processGoalReceivedCallback(obj.ActServerWeakHandle.get, msg, info);
        end
        
        function onHandleGoalAcceptedCB(obj, msg, varargin)
            % msg contains goal message and goalUUID
            % info contains goal handle
            processGoalAcceptedCallback(obj.ActServerWeakHandle.get, msg);
        end

        function onHandleGoalCancelCB(obj, msg, varargin)
            processGoalCancelCallback(obj.ActServerWeakHandle.get, msg); 
        end
    end
end
