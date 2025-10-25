classdef SvcServerObj < ros2svcserver & ...
    robotics.core.internal.mixin.Unsaveable & handle
%SVCSERVEROBJ Create a ROS 2 serivce server for Simulink
%   This is a class inherted from ros2svcserver. Instead of receiving
%   request, process, and send response at a time, this object provides
%   standalone API to send response back when it is ready.
%
%   See also ROS2SVCSERVER.

%   Copyright 2023 The MathWorks, Inc.

properties
    CurrentRequest
    IsRequestNew = false
    NumOfRequestsInQueue = 0
end

methods
    function obj = SvcServerObj(node, serviceName, serviceType, varargin)
        obj@ros2svcserver(node, serviceName, serviceType, @(~,~){}, varargin{:});
    end

    function [req, isNew] = getCurrentRequest(obj)
    %getCurrentRequest Returns the current request from buffer
        
        req = obj.CurrentRequest;
        isNew = obj.IsRequestNew;
        if isNew
            % Request has been processed, set back to false. This will
            % be set to true once a new request comes in
            obj.IsRequestNew = false;
        end
    end

    function sendResponse(obj, responseMsg)
    %sendResponse Send the response back over the network

        if obj.NumOfRequestsInQueue > 0
            try
                sendBackResponse(obj, responseMsg);
                obj.NumOfRequestsInQueue = obj.NumOfRequestsInQueue - 1;
            catch ex
                % Try to send error message back to back-end if something
                % goes wrong with the server or network

                warning(message('ros:mlros2:serviceserver:SendResponseError', ex.message))
                errorResponse.message = ex.message;
                sendBackErrorResponse(obj, errorResponse);
            end
        end
    end
end

methods (Access = ?ros.internal.mixin.InternalAccess)
    function processRequest(obj, requestMsg, varargin)
    %processRequest takes action based on new request from client

        obj.CurrentRequest = requestMsg;
        obj.IsRequestNew = true;
        obj.NumOfRequestsInQueue = obj.NumOfRequestsInQueue + 1;
    end
end

methods (Access=protected)
    function sObj = saveobj(obj)
    %saveobj Override saveobj function to avoid warning in Simulink
        % Save object in structure
        sObj.obj = obj;
    end
end
end