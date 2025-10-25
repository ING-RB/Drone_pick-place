classdef (Abstract) QOSEvents < handle
%This class is for internal use only. It may be removed in the future.

%QOSEvents Base class for publisher and subscriber ROS 2 entities
% This class is designed for handling Quality of Service (QoS) events 
% in ROS 2 entities like publishers and subscribers. It provides a mechanism to define 
% callbacks for various QoS-related events such as deadline missed, liveliness changed, 
% incompatible QoS, and message lost.

%   Copyright 2024 The MathWorks, Inc.

    properties (Dependent, SetAccess = protected)
    % Callback properties for different QoS events.

        % Callback for publisher deadline missed event
        DeadlineMissedPubQoSFcn

        % Callback for liveliness changed event
        LivelinessChangedQoSFcn

        % Callback for subscriber incompatible QoS event
        IncompatibleQoSSubFcn

        % Callback for subscriber deadline missed event
        DeadlineMissedSubQoSFcn

        % Callback for liveliness lost event
        LivelinessLostQoSFcn

        % Callback for publisher incompatible QoS event
        IncompatibleQoSPubFcn

        % Callback for message lost event
        MessageLostFcn
    end

    properties (Transient, Access = ?ros.internal.mixin.InternalAccess)
    % Actual function handles for the callbacks. 

        ActualDeadlineMissedPubQoSFcn = function_handle.empty

        ActualLivelinessLostQoSFcn = function_handle.empty

        ActualIncompatibleQoSPubFcn = function_handle.empty

        ActualDeadlineMissedSubQoSFcn = function_handle.empty

        ActualLivelinessChangedQoSFcn = function_handle.empty

        ActualIncompatibleQoSSubFcn = function_handle.empty

        ActualMessageLostFcn = function_handle.empty
        
    end

    methods
        
        % Getter for DeadlineMissedPubQoSFcn
        function value = get.DeadlineMissedPubQoSFcn(obj)
            value = obj.DeadlineMissedPubQoSFcn;
        end
        
        % Getter for LivelinessChangedQoSFcn
        function value = get.LivelinessChangedQoSFcn(obj)
            value = obj.LivelinessChangedQoSFcn;
        end
        
        % Getter for IncompatibleQoSSubFcn
        function value = get.IncompatibleQoSSubFcn(obj)
            value = obj.IncompatibleQoSSubFcn;
        end
        
        % Getter for DeadlineMissedSubQoSFcn
        function value = get.DeadlineMissedSubQoSFcn(obj)
            value = obj.DeadlineMissedSubQoSFcn;
        end
        
        % Getter for LivelinessLostQoSFcn
        function value = get.LivelinessLostQoSFcn(obj)
            value = obj.LivelinessLostQoSFcn;
        end
        
        % Getter for IncompatibleQoSPubFcn
        function value = get.IncompatibleQoSPubFcn(obj)
            value = obj.IncompatibleQoSPubFcn;
        end
        
        % Getter for MessageLostFcn
        function value = get.MessageLostFcn(obj)
            value = obj.MessageLostFcn;
        end
    
        % Setter methods for the callback properties. These methods validate the input and set the actual function handle properties.
        function set.DeadlineMissedPubQoSFcn(obj, cb)
            if isempty(cb)
                obj.ActualDeadlineMissedPubQoSFcn = function_handle.empty;
            else
                fcnHandle = ros.internal.Parsing.validateFunctionHandle(cb);
                obj.ActualDeadlineMissedPubQoSFcn = fcnHandle;
            end
        end

        function set.LivelinessLostQoSFcn(obj, cb)
            if isempty(cb)
                obj.ActualLivelinessLostQoSFcn = function_handle.empty;
            else
                fcnHandle = ros.internal.Parsing.validateFunctionHandle(cb);
                obj.ActualLivelinessLostQoSFcn = fcnHandle;
            end
        end

        function set.IncompatibleQoSPubFcn(obj, cb)
            if isempty(cb)
                obj.ActualIncompatibleQoSPubFcn = function_handle.empty;
            else
                fcnHandle = ros.internal.Parsing.validateFunctionHandle(cb);
                obj.ActualIncompatibleQoSPubFcn = fcnHandle;
            end
        end
        function set.DeadlineMissedSubQoSFcn(obj, cb)
            if isempty(cb)
                obj.ActualDeadlineMissedSubQoSFcn = function_handle.empty;
            else
                fcnHandle = ros.internal.Parsing.validateFunctionHandle(cb);
                obj.ActualDeadlineMissedSubQoSFcn = fcnHandle;
            end
        end

        function set.LivelinessChangedQoSFcn(obj, cb)
            if isempty(cb)
                obj.ActualLivelinessChangedQoSFcn = function_handle.empty;
            else
                fcnHandle = ros.internal.Parsing.validateFunctionHandle(cb);
                obj.ActualLivelinessChangedQoSFcn = fcnHandle;
            end
        end

        function set.MessageLostFcn(obj, cb)
            if isempty(cb)
                obj.ActualMessageLostFcn = function_handle.empty;
            else
                fcnHandle = ros.internal.Parsing.validateFunctionHandle(cb);
                obj.ActualMessageLostFcn = fcnHandle;
            end
        end

        function set.IncompatibleQoSSubFcn(obj, cb)
            if isempty(cb)
                obj.ActualIncompatibleQoSSubFcn = function_handle.empty;
            else
                fcnHandle = ros.internal.Parsing.validateFunctionHandle(cb);
                obj.ActualIncompatibleQoSSubFcn = fcnHandle;
            end
        end

    end

    methods (Access = protected)
        function parser = addQOSEventsToParser(obj, parser, className)
            addParameter(parser, 'DeadlineCallback', '', ...
                         @(x) validateattributes(x, {'function_handle'}, ...
                         {'nonempty'},className,'DeadlineCallback'))

            addParameter(parser, 'LivelinessCallback', '', ...
                         @(x) validateattributes(x, {'function_handle'}, ...
                         {'nonempty'},className,'LivelinessCallback'))

            addParameter(parser, 'IncompatibleQoSCallback', '', ...
                         @(x) validateattributes(x, {'function_handle'}, ...
                         {'nonempty'},className,'IncompatibleQoSCallback'))

            addParameter(parser, 'MessageLostCallback', '', ...
                         @(x) validateattributes(x, {'function_handle'}, ...
                         {'nonempty'},className,'MessageLostCallback'))

        end

    end

    methods (Access = ?ros.internal.mixin.InternalAccess)
        function deadlinePubCallback(obj, total_count, total_count_change)
            if ~isempty(obj.ActualDeadlineMissedPubQoSFcn)
                feval(obj.ActualDeadlineMissedPubQoSFcn, total_count.total_count, total_count_change.total_count_change)
            else
                warning('off', 'backtrace');
                warning(message('ros:mlros2:publisher:QoSDeadlineDefaultWarning',obj.NodeName,obj.TopicName,total_count.total_count))
                warning('on', 'backtrace');
            end
        end

        function livelinessLostCallback(obj, total_count, total_count_change)
            if ~isempty(obj.ActualLivelinessLostQoSFcn)
                feval(obj.ActualLivelinessLostQoSFcn, total_count.total_count, total_count_change.total_count_change)
            else
                warning('off', 'backtrace');
                warning(message('ros:mlros2:publisher:QoSLivelinessDefaultWarning',obj.NodeName,obj.TopicName,total_count.total_count))
                warning('on', 'backtrace');
            end
        end

        function IncompatibleQoSPubCallback(obj, total_count, total_count_change, last_kind_policy)
            if ~isempty(obj.ActualIncompatibleQoSPubFcn)
                feval(obj.ActualIncompatibleQoSPubFcn, total_count.total_count, total_count_change.total_count_change, last_kind_policy.last_policy_kind)
            else
                warning('off', 'backtrace');
                warning(message('ros:mlros2:publisher:QoSIncompatibleDefaultWarning',obj.NodeName,obj.TopicName,last_kind_policy.last_policy_kind))
                warning('on', 'backtrace');
            end
        end

        function deadlineSubCallback(obj, total_count, total_count_change)
            if ~isempty(obj.ActualDeadlineMissedSubQoSFcn)
                feval(obj.ActualDeadlineMissedSubQoSFcn, total_count.total_count, total_count_change.total_count_change)
            else
                warning('off', 'backtrace');
                warning(message('ros:mlros2:subscriber:QoSDeadlineDefaultWarning',obj.NodeName,obj.TopicName,total_count.total_count))
                warning('on', 'backtrace');
            end
        end

        function livelinessChangedCallback(obj, alive_count, alive_count_change, not_alive_count, not_alive_count_change)
            if ~isempty(obj.ActualLivelinessChangedQoSFcn)
                feval(obj.ActualLivelinessChangedQoSFcn, alive_count.alive_count, alive_count_change.alive_count_change, not_alive_count.not_alive_count, not_alive_count_change.not_alive_count_change)
            else
                % Commenting because it's not a warning, but more of info
                % for the user and not necessary for this event
                % warning('off', 'backtrace');
                % warning(message('ros:mlros2:subscriber:QoSLivelinessDefaultWarning',obj.NodeName,obj.TopicName,alive_count.alive_count,not_alive_count.not_alive_count))
                % warning('on', 'backtrace');
            end
        end

        function messageLostCallback(obj, total_count, total_count_change)
            if ~isempty(obj.ActualMessageLostFcn)
                feval(obj.ActualMessageLostFcn, total_count.total_count, total_count_change.total_count_change)
            else
                warning('off', 'backtrace');
                warning(message('ros:mlros2:subscriber:QoSMessageLostDefaultWarning',obj.NodeName,obj.TopicName,total_count.total_count))
                warning('on', 'backtrace');
            end
        end

        function IncompatibleQoSSubCallback(obj, total_count, total_count_change, last_kind_policy)
            if ~isempty(obj.ActualIncompatibleQoSSubFcn)
                feval(obj.ActualIncompatibleQoSSubFcn, total_count.total_count, total_count_change.total_count_change, last_kind_policy.last_policy_kind)
            else
                warning('off', 'backtrace');
                warning(message('ros:mlros2:subscriber:QoSIncompatibleDefaultWarning',obj.NodeName,obj.TopicName,last_kind_policy.last_policy_kind))
                warning('on', 'backtrace');
            end
        end
    end
end
