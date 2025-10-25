classdef CancelActionGoal < ros.slros2.internal.block.ROS2CancelActionGoalBase & ...
        ros.internal.mixin.InternalAccess
    %This class is for internal use only. It may be removed in the future.

    %CancelActionGoal cancel an outstanding action goal available on ROS 2
    %Network
    %
    %   H = ros.slros2.internal.block.CancelActionGoal creates a system
    %   object, H, that sends a cancel goal request to an action server on
    %   the ROS2 network based on the input unique_identifier_msgs/UUID 
    %   message and outputs the cancel goal response received of type
    %   action_msgs/CancelGoalResponse.
    %
    %   This system object is intended for use with the MATLAB System
    %   block. In order to access the ROS 2 functionality from MATLAB, see
    %   ROS2ACTIONCLIENT.
    %
    %   See also ros2actionclient.
    %

    %   Copyright 2023 The MathWorks, Inc.
    
    %#codegen

    properties (Constant, Access=?ros.slros.internal.block.mixin.NodeDependent)
        %MessageCatalogName - Name of this block used in message catalog
        %   This property is used by the NodeDependent base class to
        %   customize error messages with the block name.
         
        %   Due a limitation in Embedded MATLAB code-generation with UTF-8 characters,
        %   use English text instead
        MessageCatalogName = 'ROS 2 Cancel Action Goal'
    end

    properties (Access=private, Transient)
        % pLatestCancelRespMessage - latest cancel response message available
        % from callback
        pLatestCancelRespMessage = []

        % cancelResultOutputConverter - Conversion for cancel goal response bus
        cancelResultOutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter.empty
    end

    properties (Access = protected)
        % CancelGoalOutputConversionFcn Conversion function for output message
        CancelGoalOutputConversionFcn

        % EmptySeedCancelResponseBusStruct Empty Seed output ROS 2 Message
        EmptySeedCancelResponseBusStruct
    end

    methods (Access = protected)
        function num = getNumInputsImpl(~)
            num = 3;
        end

        function num = getNumOutputsImpl(~)
            num = 2;
        end

        function varargout = getOutputSizeImpl(~)
            varargout = {[1 1], [1 1]};
        end

        function varargout = isOutputFixedSizeImpl(~)
            varargout = {true, true};
        end

        function varargout = getOutputDataTypeImpl(obj)
            varargout =  {obj.SLResponseOutputBusName, 'uint8'};
        end

        function varargout = isOutputComplexImpl(~)
            varargout = {false, false};
        end

        function sts = getSampleTimeImpl(obj)
            %getSampleTimeImpl Return sample time specification

            % Enable this system object to inherit constant ('inf') sample
            % times
            sts = createSampleTime(obj, 'Type', 'Inherited', 'Allow', 'Constant');
        end
    end

    methods (Access = protected, Static)
        function header = getHeaderImpl
        % Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"), ...
                                                  'ShowSourceLink', false, ...
                                                  'Title', 'ROS 2 Cancel Action Goal', ...
                                                  'Text', message('ros:slros2:blockmask:CancelActionGoalDescription').getString);
        end

        function throwSimStateError()
            coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS 2 Cancel Action Goal');
        end

    end

    methods (Access = protected)
        function setupImpl(obj)
            %setupImpl is called when model is being initialized at the start
            %of a simulation. Perform one-time calculations, such as computing constants
            if coder.target('MATLAB')
                % Only run simulation setup if it is not in code generation
                % process
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Executing in MATLAB interpreted mode
                    obj.cancelResultOutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter(...
                        'action_msgs/CancelGoalResponse', obj.ModelName);

                    emptySeedCancelResponseMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType('action_msgs/CancelGoalResponse');
                    obj.EmptySeedCancelResponseBusStruct = obj.cancelResultOutputConverter.convert(emptySeedCancelResponseMsg);

                    [emptyCancelGoalRespMsg,cancelGoalRespMsgInfo]= ros.internal.getEmptyMessage('action_msgs/CancelGoalResponse','ros2');
                    cachedMap = containers.Map();
                    % This map contains the values of empty message data which
                    % can be reused when required.
                    refCachedMapOutStoragePath = fullfile(pwd, '+bus_conv_fcns','+ros2','+msgToBus','RefCachedMap.mat');
                    refCachedMapOut = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapOutStoragePath);
                    cachedMap('action_msgs/CancelGoalResponse') = emptyCancelGoalRespMsg;

                    [cancelGoalPkgNameOut,cancelGoalMsgNameOut] = fileparts('action_msgs/CancelGoalResponse');
                    obj.CancelGoalOutputConversionFcn = generateStaticConversionFunctions(obj,emptyCancelGoalRespMsg,...
                        cancelGoalRespMsgInfo,'ros2','msgToBus',cancelGoalPkgNameOut,cancelGoalMsgNameOut,cachedMap,refCachedMapOut,refCachedMapOutStoragePath);
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is importatn to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Cancel Action Goal');
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

        function [cancelRespMsg, errorCode] = stepImpl(obj,inputbusstruct, enablesignal, outputbusstruct)
            % stepImpl - Cancel an Action Goal Message and output cancel
            % response message. Buses are treated as structures

            errorCode = uint8(ros.slros.internal.block.CancelGoalErrorCode.SLCancelGoalSuccess);

            if coder.target('MATLAB')
                % Execute in interpreted mode
                cancelRespMsg = outputbusstruct;

                if all(inputbusstruct.uuid == 0)
                    % Show error code 3 when uuid output of send goal contains zeros, as server is unavailable
                    % Cancel response output will be default message
                    errorCode = uint8(ros.slros.internal.block.CancelGoalErrorCode.SLCancelGoalServerUnavailable);
                    return
                end

                if enablesignal
                    [goalHandle, status, errorCode] = ros.ros2.internal.checkGoalHandleAndServer(inputbusstruct.uuid);
                    if ~status
                        return
                    end
                    % If there is any outstanding goal, and enable input is
                    % true, cancel the outstanding goal.
                    try
                        cancelGoal(goalHandle, "CancelFcn",@executeCancelCb);
                    catch
                        % If the goal is already in canceling or terminated
                        % state, handle the exception by showing the
                        % error code 1 with default cancel response.
                        errorCode = uint8(ros.slros.internal.block.CancelGoalErrorCode.SLCancelGoalTerminated);
                        return
                    end
                end

                if isempty(obj.pLatestCancelRespMessage)
                    % If the cancel response is not available, show the
                    % default response
                    return
                end

                % If the cancel response is available, show the cancel
                % response received from the server
                cancelRespMsg = obj.CancelGoalOutputConversionFcn(obj.pLatestCancelRespMessage, obj.EmptySeedCancelResponseBusStruct, '',obj.ModelName,obj.Cast64BitIntegersToDouble);
                % Reset the latest cancel response message after the cancel
                % response is available and shown on the output port.
                % As it is not required to show cancel response message
                % when a new goal is in progress 
                obj.pLatestCancelRespMessage = [];
            elseif coder.target('Rtw')
                % Code generation
                cancelRespMsg = outputbusstruct;
                isServerConnected = false;
                isGoalHandleAvailable = false;
                coder.ceval([obj.BlockId, '.setSimActClientForUUID'], coder.rref(inputbusstruct));
                isGoalHandleAvailable = coder.ceval([obj.BlockId, '.isGoalHandleAvailable']);
                if ~isGoalHandleAvailable
                    % Show error code 2 when there is no goal handle
                    % Cancel response output will be default message
                    errorCode = uint8(ros.slros.internal.block.CancelGoalErrorCode.SLCancelGoalInvalidUUID);
                    return
                end
                isServerConnected = coder.ceval([obj.BlockId, '.isServerConnected']);
                if ~isServerConnected
                    % Show ErrorCode if action server is not available
                    % Show UUID output as default message
                    errorCode = uint8(ros.slros.internal.block.CancelGoalErrorCode.SLCancelGoalServerUnavailable);
                    return
                end

                if enablesignal
                    % If there is any outstanding goal, and enable input is
                    % true, cancel the outstanding goal.
                    coder.ceval([obj.BlockId, '.cancelGoal'], coder.wref(errorCode));
                    if(errorCode == uint8(ros.slros.internal.block.CancelGoalErrorCode.SLCancelGoalTerminated))
                        % If the goal is already in canceling or terminated
                        % state, handle the exception by showing the
                        % error code 1 with default cancel response.
                        return
                    end
                end
                % If the cancel response is available, show the cancel
                % response received from the server
                coder.ceval([obj.BlockId, '.getCancelResponse'],coder.wref(cancelRespMsg));
            end

            function executeCancelCb(~, msg)
                obj.pLatestCancelRespMessage = msg;
            end
        end
    end
end
