classdef MonitorActionGoalBlockMask < ros.slros.internal.block.CommonActionMask
%This class is for internal use only. It may be removed in the future.

%MonitorActionGoalBlockMask - Block mask callbacks for ROS 2 Monitor Action Goal
%block

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'ROS 2 Monitor Action Goal'

        %FeedbackMsgSinkName - Name of sink block for FeedbackMsg in subsystem
        %   In practice, this block is either a terminator (if user does
        %   not want the output) or a standard outport.
        FeedbackMsgSinkName = 'FeedbackMsgOut'

        %ErrorCodeSinkName - Name of sink block for ErrorCode in subsystem
        %   In practice, this block is either a terminator (if user does
        %   not want the output) or a standard outport.
        ErrorCodeSinkName = 'ErrorCodeOut'

        %DefaultPrompt - Default prompt for hyperlink text
        DefaultPrompt = 'ros:slros2:blockmask:NoSendGoalPairedBlkPrompt'
    end

    properties (Constant)
        %% Abstract properties inherited from CommonMask base class
        MaskParamIndex = struct( ...
            'ActionNameEdit', 1, ...
            'ActionTypeEdit', 2 ...
            );

        MaskDlgIndex = [];

        SysObjBlockName = 'MonitorGoal';
    end

    methods
        function updateSubsystem(obj, block)
        %updateSubsystem Callback executed on subsystem update

        % There are 4 blocks in the subsystem
        %  * The MATLAB System block with name SysObjBlockName
        %  * The Signal Specification block
        %  * A Constant block for Result bus type
        %  * A Constant block for Feedback bus type
            sysobjBlock = [block '/' obj.SysObjBlockName];
            sigspecBlock = [block '/SignalSpecification'];
            constBlock = [block '/Constant'];
            constBlock1 = [block '/Constant1'];

            rosActionType = get_param(block, 'actionType');
            [~,~, slResultOutputBusDataType, slResultOutputBusName, slFbOutputBusDataType, slFbOutputBusName] = ...
                ros.slros2.internal.bus.Util.rosActionTypeToDataTypeStr(rosActionType);

            if ~ros.slros.internal.block.CommonActionMask.isLibraryBlock(block)
                rosFeedbackMessageType = strcat(rosActionType, 'Feedback');
                rosResultMessageType = strcat(rosActionType, 'Result');
                ros.slros2.internal.bus.Util.createBusIfNeeded(rosFeedbackMessageType,bdroot(block));
                ros.slros2.internal.bus.Util.createBusIfNeeded(rosResultMessageType,bdroot(block));
            end

            [uuidMsgBusDataType,uuidMsgBusName] = ros.slros2.internal.bus.Util.rosMsgTypeToDataTypeStr('unique_identifier_msgs/UUID');
            modelName = bdroot(block);

            set_param(sysobjBlock, 'SLUUIDInputBusName', uuidMsgBusName);
            set_param(sysobjBlock, 'SLFeedbackOutputBusName', slFbOutputBusName);
            set_param(sysobjBlock, 'SLResultOutputBusName', slResultOutputBusName);
            set_param(sysobjBlock, 'ModelName', modelName);
            set_param(sigspecBlock, 'OutDataTypeStr', uuidMsgBusDataType);
            set_param(constBlock, 'OutDataTypeStr', slResultOutputBusDataType);
            set_param(constBlock1, 'OutDataTypeStr', slFbOutputBusDataType);

            if ~strcmp(bdroot(block),'ros2lib')
                % Update mask and paired block
                [foundPairedBlk, pairedBlkH, ~] = ros.slros.internal.ROSUtil.getMatchingClientBlkByAction(block,'action');
                if foundPairedBlk
                    % set BlockId and actionType retrieved from paired
                    % block. 
                    % There is no need to set hyperlink since it has been
                    % set when finding paired block.
                    blkH = get_param(block, 'handle');
                    set_param(blkH,'BlockId',get_param(pairedBlkH,'BlockId'));
                    set_param(blkH,'actionType',get_param(pairedBlkH,'actionType'));
                end
            end
        end

        function maskInitialize(obj, block)
        %maskInitialize Mask initialization callback
        %   It is invoked when the user:
        %   * Changes the value of a mask parameter by using the block dialog box or set_param.
        %   * Changes any of the parameters that define the mask
        %   * Causes the icon to be redrawn
        %   * Copies the block
        %
        %   Mask initialization is invoked after the individual parameter
        %   callbacks

        % Show or hide the FeedbackMsg output port
            showFeedback = get_param(block, 'ShowFeedbackOutput');

            % existingErrorCodeSink is the sink block for the ErrorCode output in
            % the current subsystem. This can either be a standard outport,
            % or a terminator.
            existingFeedbackMsgSink = [block '/' obj.FeedbackMsgSinkName];

            % Determine what type the sink block should be based on the
            % checkbox setting on the mask.
            if strcmp(showFeedback, 'on')
                newFeedbackMsgSink = sprintf('built-in/Outport');
            else
                newFeedbackMsgSink = sprintf('built-in/Terminator');
            end

            % Only modify the subsystem if new block type is different
            existingFbOutportType = get_param(existingFeedbackMsgSink, 'BlockType');
            newFbOutportType = get_param(newFeedbackMsgSink, 'BlockType');
            if ~strcmp(existingFbOutportType, newFbOutportType)
                % Preserve orientation and position to ensure that the
                % existing signal line connects without any issues.
                orient  = get_param(existingFeedbackMsgSink, 'Orientation');
                pos     = get_param(existingFeedbackMsgSink, 'Position');
                delete_block(existingFeedbackMsgSink);
                add_block(newFeedbackMsgSink, existingFeedbackMsgSink, ...
                          'Name',        obj.FeedbackMsgSinkName, ...
                          'Orientation', orient, ...
                          'Position',    pos);
            end

            % Show or hide the ErrorCode output port
            showErrorCode = get_param(block, 'ShowErrorCodeOutput');

            % existingErrorCodeSink is the sink block for the ErrorCode output in
            % the current subsystem. This can either be a standard outport,
            % or a terminator.
            existingErrorCodeSink = [block '/' obj.ErrorCodeSinkName];

            % Determine what type the sink block should be based on the
            % checkbox setting on the mask.
            if strcmp(showErrorCode, 'on')
                newErrorCodeSink = sprintf('built-in/Outport');
            else
                newErrorCodeSink = sprintf('built-in/Terminator');
            end

            % Only modify the subsystem if new block type is different
            existingOutportType = get_param(existingErrorCodeSink, 'BlockType');
            newOutportType = get_param(newErrorCodeSink, 'BlockType');
            if ~strcmp(existingOutportType, newOutportType)
                % Preserve orientation and position to ensure that the
                % existing signal line connects without any issues.
                orient  = get_param(existingErrorCodeSink, 'Orientation');
                pos     = get_param(existingErrorCodeSink, 'Position');
                delete_block(existingErrorCodeSink);
                add_block(newErrorCodeSink, existingErrorCodeSink, ...
                          'Name',        obj.ErrorCodeSinkName, ...
                          'Orientation', orient, ...
                          'Position',    pos);
            end

            blkH = get_param(block, 'handle');
            % set block mask display
            actionName = get_param(block,'action');
            maskDisplayText = sprintf('color(''black'');');
            if length(actionName) > 20
                maskDisplayText = sprintf('%s\ntext(0.95, 0.15, ''%s'', ''horizontalAlignment'', ''right'');', ...
                                          maskDisplayText, actionName);
            else
                maskDisplayText = sprintf('%s\ntext(0.5, 0.15, ''%s'', ''horizontalAlignment'', ''center'');', ...
                                          maskDisplayText, actionName);
            end

            inPort = 1;
            maskDisplayText = sprintf('%s\nport_label(''input'', %d, ''UUID'');',maskDisplayText, inPort);

            outPort = 1;
            maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''StatusCode'');',maskDisplayText, outPort);
            outPort = outPort + 1;
            maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''Result'');',maskDisplayText, outPort);
            if isequal(get_param(block, 'ShowFeedbackOutput'), 'on')
                outPort = outPort + 1;
                maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''Feedback'');',maskDisplayText, outPort);
            end
            if isequal(get_param(block, 'ShowErrorCodeOutput'), 'on')
                outPort = outPort + 1;
                maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''ErrorCode'');',maskDisplayText, outPort);
            end

            % Set the block mask display and icon
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            ros.internal.setBlockIcon(blkH, 'rosicons.ros2lib_monitorActionGoal');

            rosMessageType = 'unique_identifier_msgs/UUID';
            if ~ros.slros.internal.block.CommonActionMask.isLibraryBlock(block)
                ros.slros2.internal.bus.Util.createBusIfNeeded(rosMessageType,bdroot(block));
            end

            % Create bus for Monitor Action Goal block if such bus has not been
            % loaded yet
            updateSubsystem(obj,block);
        end

        function copyBlockInit(obj,block)
        %copyBlockInit Mask initialization for copy block
        %   This function helps the new copied block to find potential
        %   paring block and setup parameters.

            ros.slros.internal.ROSUtil.copyBlkCallback(block,'action', obj.DefaultPrompt);
        end
    end

    methods(Static)
        function ret = getMaskType()
            ret = 'ROS 2 Monitor Action Goal';
        end

        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros2.internal.block.MonitorActionGoalBlockMask;
            obj.(methodName)(varargin{:});
        end
    end
end