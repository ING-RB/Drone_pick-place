classdef MonitorActionGoal < ros.slros2.internal.block.ROS2MonitorActionGoalBase & ...
        ros.internal.mixin.InternalAccess
    %This class is for internal use only. It may be removed in the future.

    % MonitorActionGoal monitor an action goal sent over a ROS 2 network
    %
    %   H = ros.slros2.internal.block.MonitorActionGoal creates a system
    %   object, H, that monitors a goal based on the input unique_identifer_msgs/UUID
    %   message. This block outputs the status, feedback, result and error code
    %   for a specific goal.
    %
    %   This system object is intended for use with the MATLAB System
    %   block. In order to access the ROS 2 functionality from MATLAB, see
    %   ROS2ACTIONCLIENT.
    %
    %   See also ros2actionclient.
    
    %   Copyright 2023 The MathWorks, Inc.
    
    %#codegen

    properties (Constant, Access=?ros.slros.internal.block.mixin.NodeDependent)
        % MessageCatalogName - Name of this block used in message catalogs
        MessageCatalogName = message("ros:slros2:blockmask:MonitorActionGoalMaskTitle").getString
    end

    properties (Nontunable)
        %ActionName Name of the action
        %   This system object will use ActionName as specified in both
        %   simulation and code generation. In particular, it will not add
        %   a "/" in front of topic, as that forces the topic to be in the
        %   absolute namespace.
        ActionName = '/fibonacci'

        %ActionType Type of the action
        ActionType = 'example_interfaces/Fibonacci'
    end

    properties (Access=private, Transient)
        % resultOutputConverter - Conversion for goal result bus
        resultOutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter.empty

        % feedbackOutputConverter - Conversion for feedback goal response bus
        feedbackOutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter.empty
    end

    properties (Access = protected)
        % ResultOutputConversionFcn Conversion function for output message
        ResultOutputConversionFcn
        % FeedbackOutputConversionFcn Conversion function for output message
        FeedbackOutputConversionFcn
        % EmptySeedResultOutputBusStruct Empty Seed output ROS 2 Message
        EmptySeedResultOutputBusStruct
        % EmptySeedFeedbackOutputBusStruct Empty Seed output ROS 2 Message
        EmptySeedFeedbackOutputBusStruct
    end

    methods (Access = protected)
        function num = getNumInputsImpl(~)
            num = 3;
        end

        function num = getNumOutputsImpl(~)
            num = 4;
        end

        function varargout = getOutputSizeImpl(~)
            varargout = {[1 1], [1 1], [1 1], [1 1]};
        end

        function varargout = isOutputFixedSizeImpl(~)
            varargout = {true, true, true, true};
        end

        function varargout = getOutputDataTypeImpl(obj)
            varargout =  {'int8', obj.SLResultOutputBusName, obj.SLFeedbackOutputBusName, 'uint8'};
        end

        function varargout = isOutputComplexImpl(~)
            varargout = {false, false, false, false};
        end

        function sts = getSampleTimeImpl(obj)
            % Define sample time type and parameters
            sts = createSampleTime(obj, 'Type', 'Inherited', 'Allow', 'Constant');
        end
    end

    methods (Access = protected, Static)
        function header = getHeaderImpl
        % Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"), ...
                                                  'ShowSourceLink', false, ...
                                                  'Title', message("ros:slros2:blockmask:MonitorActionGoalMaskTitle").getString, ...
                                                  'Text', message('ros:slros2:blockmask:MonitorActionGoalDescription').getString);
        end

        function throwSimStateError()
            coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS 2 Monitor Action Goal');
        end
    end

    methods (Access = protected)
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            if coder.target('MATLAB')
                % Only run simulation setup if it is not in code generation
                % process
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Executing in MATLAB interpreted mode
                    % Setup Feedback message to bus converter
                    obj.feedbackOutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter(...
                        strcat(obj.ActionType, 'Feedback'), obj.ModelName);
                    emptySeedFeedbackOutputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType([obj.ActionType 'Feedback']);
                    obj.EmptySeedFeedbackOutputBusStruct = obj.feedbackOutputConverter.convert(emptySeedFeedbackOutputMsg);
                    [emptyFeedbackOutputMsg,feedbackOutputMsgInfo]= ros.internal.getEmptyMessage([obj.ActionType 'Feedback'],'ros2');

                    % Setup Result message to bus converter
                    obj.resultOutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter(...
                        strcat(obj.ActionType, 'Result'), obj.ModelName);
                    emptySeedResultOutputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType([obj.ActionType 'Result']);
                    obj.EmptySeedResultOutputBusStruct = obj.resultOutputConverter.convert(emptySeedResultOutputMsg);
                    [emptyResultOutputMsg,resultOutputMsgInfo]= ros.internal.getEmptyMessage([obj.ActionType 'Result'],'ros2');

                    cachedMap = containers.Map();
                    % This map contains the values of empty message data which
                    % can be reused when required.
                    refCachedMapOutStoragePath = fullfile(pwd, '+bus_conv_fcns','+ros2','+msgToBus','RefCachedMap.mat');
                    refCachedMapOut = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapOutStoragePath);
                    cachedMap([obj.ActionType 'Result']) = emptyResultOutputMsg;
                    [pkgNameOut,resultMsgNameOut] = fileparts([obj.ActionType 'Result']);
                    cachedMap([obj.ActionType 'Feedback']) = emptyFeedbackOutputMsg;
                    [~,feedbackMsgNameOut] = fileparts([obj.ActionType 'Feedback']);
                    obj.ResultOutputConversionFcn = generateStaticConversionFunctions(obj,emptyResultOutputMsg,...
                        resultOutputMsgInfo,'ros2','msgToBus',pkgNameOut,resultMsgNameOut,cachedMap,refCachedMapOut,refCachedMapOutStoragePath);
                    obj.FeedbackOutputConversionFcn = generateStaticConversionFunctions(obj,emptyFeedbackOutputMsg,...
                        feedbackOutputMsgInfo,'ros2','msgToBus',pkgNameOut,feedbackMsgNameOut,cachedMap,refCachedMapOut,refCachedMapOutStoragePath);
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is importatn to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Monitor Action Goal');
            elseif coder.target('Rtw')
                % Header files has been included in Send Action Goal block
                % Do nothing
            elseif coder.target('Sfun')
                % 'Sfun'  - Simulation through CodeGen target
                % Do nothing. MATLAB System block first does a pre-codegen
                % compile with 'Sfun' target, & then does the "proper"
                % codegen compile with Rtw or RtwForRapid, as appropriate.
            else
                % 'RtwForSim' - ModelReference SIM target
                % 'MEX', 'HDL', 'Custom' - Not applicable to MATLAB System block
                coder.internal.errorIf(true, 'ros:slros:sysobj:UnsupportedCodegenMode', coder.target);
            end
        end

        function [statusCode, resultMsg, feedbackMsg, errorCode] = stepImpl(obj, inputbusstruct, outputresultbusstruct, outputfeedbackbusstruct)
            % Execute the step to monitor action feedback, status and fetch the
            % final result for a goal sent using Send Action Goal block

            errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalSuccess);
            % Initial status of the goal - indicates goal is not available
            % or not accepted by the action server.
            statusCode = int8(-1);

            if coder.target('MATLAB')
                % Execute in interpreted mode
                resultMsg = outputresultbusstruct; %return empty bus for result
                feedbackMsg = outputfeedbackbusstruct; %return empty bus for feedback

                if all(inputbusstruct.uuid == 0)
                    % Show error code 3 when uuid output of send goal contains zeros, as server is unavailable
                    % Feedback and result outputs will be default messages
                    errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalServerUnavailable);
                    return
                end

                [goalHandle, status, errorCode] = ros.ros2.internal.checkGoalHandleAndServer(inputbusstruct.uuid);
                if ~status
                    return
                end

                if(goalHandle.Status == -1)
                    % Show error code 1 for empty or rejected goal handle
                    % Feedback and result outputs will be default messages
                    errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalRejected);
                    return
                end

                % When the goal is in progress - show the feedback output
                % and default result message.
                if isKey(goalHandle.LatestInfoMapForFeedbackCB,'FeedbackFcn')
                    % Show Feedback output when it is available, otherwise
                    % show default feedback.
                    latestFeedback = goalHandle.LatestInfoMapForFeedbackCB('FeedbackFcn');
                    if ~isempty(latestFeedback)
                        feedbackMsg = obj.FeedbackOutputConversionFcn(latestFeedback, obj.EmptySeedFeedbackOutputBusStruct,'',obj.ModelName,obj.Cast64BitIntegersToDouble);
                    end
                end

                % When the goal is in final state - SUCCEEDED, CANCELED
                % or ABORTED, show the result and feedback outputs.
                statusCode = goalHandle.Status;
                terminalStatesForAcceptedGoals = {ros.slros2.internal.block.GoalTerminalStates.SLSucceeded, ...
                    ros.slros2.internal.block.GoalTerminalStates.SLCanceled, ...
                    ros.slros2.internal.block.GoalTerminalStates.SLAborted};

                if any(cellfun(@(x) isequal(x, statusCode), terminalStatesForAcceptedGoals))
                    % Show Result output when the goal is in terminal state,
                    % otherwise show default result.
                    resultMessage = getResult(goalHandle);
                    resultMsg = obj.ResultOutputConversionFcn(resultMessage, obj.EmptySeedResultOutputBusStruct,'',obj.ModelName,obj.Cast64BitIntegersToDouble);
                end
            elseif coder.target('Rtw')
                % Code generation
                resultMsg = outputresultbusstruct;
                feedbackMsg = outputfeedbackbusstruct;
                isServerConnected = false;
                isServerConnected = coder.ceval([obj.BlockId,'.isServerConnected']);
                if ~isServerConnected
                    % Show ErrorCode if action server is not available
                    % Show UUID output as default message
                    errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalServerUnavailable);
                    return
                end

                isGoalHandleAvailable = false;
                isGoalHandleAvailable = coder.ceval([obj.BlockId, '.isGoalHandleAvailable']);
                if ~isGoalHandleAvailable
                    % Show error code 2 for empty goal handle
                    % Feedback and result outputs will be default messages
                     errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalInvalidUUID);
                     return;
                end

                % When the goal is in final state - SUCCEEDED, CANCELED
                % or ABORTED, show the result and feedback outputs.
                statusCode = coder.ceval([obj.BlockId, '.getStatus']);
                if(statusCode == -1)
                    % Show error code 1 for empty or rejected goal handle
                    % Feedback and result outputs will be default messages
                    errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalRejected);
                    return
                end

                coder.ceval([obj.BlockId, '.getLatestFeedback'], coder.wref(feedbackMsg));

                terminalStatesForAcceptedGoals = {ros.slros2.internal.block.GoalTerminalStates.SLSucceeded, ...
                    ros.slros2.internal.block.GoalTerminalStates.SLCanceled, ...
                    ros.slros2.internal.block.GoalTerminalStates.SLAborted};

                % Show Result output when the goal is in terminal state,
                % otherwise show default result.
                isResultReady = false;
                isResultReady = coder.ceval([obj.BlockId,'.isResultReady']);
                if isResultReady
                    statusCode = coder.ceval([obj.BlockId, '.getStatus']);
                end
                if any(cellfun(@(x) isequal(x, statusCode), terminalStatesForAcceptedGoals))
                    coder.ceval([obj.BlockId, '.getResult'], coder.wref(resultMsg));
                end
            end
        end
    end
end
