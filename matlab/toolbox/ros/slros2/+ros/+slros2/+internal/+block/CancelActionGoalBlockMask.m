classdef CancelActionGoalBlockMask < ros.slros.internal.block.CommonActionMask
%This class is for internal use only. It may be removed in the future.

%CancelActionGoalBlockMask - Block mask callbacks for ROS 2 Cancel Action Goal
%block

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'ROS 2 Cancel Action Goal'

        %ErrorCodeSinkName - Name of sink block for ErrorCode in subsystem
        %   In practice, this block is either a terminator (if user does
        %   not want the output) or a standard outport.
        ErrorCodeSinkName = 'ErrorCodeOut'
    end

    properties (Constant)
        %% Abstract properties inherited from CommonActionMask base class
        MaskParamIndex = struct.empty();

        MaskDlgIndex = struct.empty();

        SysObjBlockName = 'CancelGoal';
    end

    methods
        function updateSubsystem(obj, block)
        %updateSubsystem Callback executed on subsystem update

        % There are 3 blocks in the subsystem
        %  * The MATLAB System block with name SysObjBlockName
        %  * A Constant block
            sysobjBlock = [block '/' obj.SysObjBlockName];
            constBlock = [block '/Constant'];

            [~,uuidMsgBusName] = ros.slros2.internal.bus.Util.rosMsgTypeToDataTypeStr('unique_identifier_msgs/UUID');
            if ~ros.slros.internal.block.CommonActionMask.isLibraryBlock(block)
                ros.slros2.internal.bus.Util.createBusIfNeeded('action_msgs/CancelGoalResponse',bdroot(block));
            end
            [responseMsgBusDataType,responseMsgBusName] = ros.slros2.internal.bus.Util.rosMsgTypeToDataTypeStr('action_msgs/CancelGoalResponse');

            % note: we use the block id of the parent, not the sys_obj block
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'ActCancel_');
            modelName = bdroot(block);

            set_param(sysobjBlock, 'SLResponseOutputBusName', responseMsgBusName);
            set_param(sysobjBlock, 'SLUUIDInputBusName', uuidMsgBusName);
            set_param(sysobjBlock, 'ModelName', modelName);
            set_param(block, 'BlockId', blockId);
            set_param(constBlock, 'OutDataTypeStr', responseMsgBusDataType);
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

            % set block mask display
            blkH = get_param(block, 'handle');
            maskDisplayText = sprintf('color(''black'');');

            inPort = 1;
            maskDisplayText = sprintf('%s\nport_label(''input'', %d, ''UUID'');',maskDisplayText, inPort);
            inPort = 2;
            maskDisplayText = sprintf('%s\nport_label(''input'', %d, ''Enable'');',maskDisplayText, inPort);

            outPort = 1;
            maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''Response'');',maskDisplayText, outPort);
            if isequal(get_param(block, 'ShowErrorCodeOutput'), 'on')
                outPort = outPort + 1;
                maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''ErrorCode'');',maskDisplayText, outPort);
            end
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            ros.internal.setBlockIcon(blkH, 'rosicons.ros2lib_cancelActionGoal');

            rosMessageType = 'unique_identifier_msgs/UUID';
            if ~ros.slros.internal.block.CommonActionMask.isLibraryBlock(block)
                ros.slros2.internal.bus.Util.createBusIfNeeded(rosMessageType,bdroot(block));
            end

            % Create bus for Cancel Action Goal block if such bus has not been
            % loaded yet
            updateSubsystem(obj,block);
        end
    end

    methods(Static)
        function ret = getMaskType()
            ret = 'ROS 2 Cancel Action Goal';
        end

        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros2.internal.block.CancelActionGoalBlockMask;
            obj.(methodName)(varargin{:});
        end

    end
end