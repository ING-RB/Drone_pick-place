classdef SendActionGoalBlockMask < ros.slros.internal.block.CommonActionMask
%This class is for internal use only. It may be removed in the future.

%SendActionGoalBlockMask - Block mask callbacks for ROS 2 Send Action Goal
%block

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'ROS 2 Send Action Goal'

        %ErrorCodeSinkName - Name of sink block for ErrorCode in subsystem
        %   In practice, this block is either a terminator (if user does
        %   not want the output) or a standard outport.
        ErrorCodeSinkName = 'ErrorCodeOut'

        %DefaultPrompt - Default prompt for hyperlink text
        DefaultPrompt = 'ros:slros2:blockmask:NoMonitorGoalPairedBlkPrompt'
    end

    properties (Constant)
        %% Abstract properties inherited from CommonActionMask base class
        MaskParamIndex = struct( ...
            'SourceDropdown', 1, ...
            'ActionNameEdit', 2, ...
            'ActionTypeEdit', 3 ...
            );

        MaskDlgIndex = struct( ...
            'ActionSelect', [2 3], ...       % Action Group Box > Action Select Button
            'ActionTypeSelect', [2 5] ...    % Action Group Box > Action Type Select Button
            );

        SysObjBlockName = 'SendGoal';
    end

    methods
        function actionSourceSelect(obj, block)
        %actionSourceSelect Source of the action name has changed

            maskValues = get_param(block, 'MaskValues');
            maskVisibilities = get_param(block, 'MaskVisibilities');
            maskEnables = get_param(gcb,'MaskEnables');

            mask = Simulink.Mask.get(block);
            dlg = mask.getDialogControls;

            d = obj.MaskDlgIndex.ActionSelect;
            m = obj.MaskDlgIndex.ActionTypeSelect;

            if strcmpi(maskValues{obj.MaskParamIndex.SourceDropdown}, obj.TopicSourceSpecifyOwn)
                % Custom topic
                % Enable editing of topic
                maskEnables{obj.MaskParamIndex.ActionNameEdit} = 'on';
                % Hide Topic selection button
                dlg(d(1)).DialogControls(1).DialogControls(d(2)).Visible = 'off';
                % Show MessageType selection button
                dlg(m(1)).DialogControls(1).DialogControls(m(2)).Visible = 'on';
            else % select topic from ROS network
                 % Disable editing of topic
                maskEnables{obj.MaskParamIndex.ActionNameEdit} = 'off';
                % Show Topic selection button
                dlg(d(1)).DialogControls(1).DialogControls(d(2)).Visible = 'on';
                % Hide MessageType selection button
                dlg(m(1)).DialogControls(1).DialogControls(m(2)).Visible = 'off';
            end

            set_param(gcb,'MaskEnables', maskEnables);
            set_param(gcb,'MaskVisibilities', maskVisibilities);
        end

        function updateSubsystem(obj, block)
        %updateSubsystem Callback executed on subsystem update

        % There are 3 blocks in the subsystem
        %  * The MATLAB System block with name SysObjBlockName
        %  * The Signal Specification block
        %  * A Constant block for output UUID bus type
            sysobjBlock = [block '/' obj.SysObjBlockName];
            sigspecBlock = [block '/SignalSpecification'];
            constBlock = [block '/Constant'];

            % Do not canonicalize the action name (i.e., if user entered
            % "foo", don't convert it to "/foo"). This enables user to
            % control whether to have a relative or absolute action name in
            % generated code.
            actionName = get_param(block, 'action');
            rosActionType = get_param(block, 'actionType');

            [slGoalInputBusDataType,slGoalInputBusName, ~, ~, ~, ~] = ...
                ros.slros2.internal.bus.Util.rosActionTypeToDataTypeStr(rosActionType);
            [uuidMsgBusDataType,~] = ros.slros2.internal.bus.Util.rosMsgTypeToDataTypeStr('unique_identifier_msgs/UUID');

            % note: we use the block id of the parent, not the sys_obj block
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'ActSend_');
            modelName = bdroot(block);

            set_param(sysobjBlock, 'SLGoalInputBusName', slGoalInputBusName);
            set_param(sysobjBlock, 'ActionType', rosActionType);
            set_param(sysobjBlock, 'ActionName', actionName);
            set_param(sysobjBlock, 'ModelName', modelName);
            set_param(block, 'BlockId', blockId);
            set_param(sigspecBlock, 'OutDataTypeStr', slGoalInputBusDataType);
            set_param(constBlock, 'OutDataTypeStr', uuidMsgBusDataType);
        end

        function actionEdit(obj, block)
        %actionEdit - Callback when action name changes

            sysobj_block = [block '/' obj.SysObjBlockName];
            curValue = get_param(sysobj_block, 'ActionName');
            newValue = get_param(block,'action');

            % Check for validity and make sure that the name is a valid
            % ROS2 name
            if ~ros.internal.Namespace.isValidGraphName(newValue)
                set_param(block, 'action', curValue);
                error(message('ros:slros2:blockmask:InvalidActionName', newValue));
            end

            % Update paired block if exists
            obj.updatePairedBlkMaskParam(block, 'action', newValue);
            obj.messageLoadFcn(block);
            obj.updateSubsystem(block);
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

            if ~strcmp(bdroot(block),'ros2lib')
                % Update mask and paired block
                [foundPairedBlk, blkH, ~] = ros.slros.internal.ROSUtil.getMatchingClientBlkByAction(block,'action');
                maskObj = Simulink.Mask.get(block);
                pairedBlkLnk = maskObj.getDialogControl('PairedBlkLink');
    
                if foundPairedBlk
                    % Ensure block hyperlink indicates correct path
                    if ~strcmp(pairedBlkLnk.Prompt, getfullname(blkH))
                        pairedBlkLnk.Prompt = getfullname(blkH);
                    end
                else
                    % Reset hyperlink
                     pairedBlkLnk.Prompt = obj.DefaultPrompt;
                end
            end
            
            % set block mask display
            blkH = get_param(block, 'handle');
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
            maskDisplayText = sprintf('%s\nport_label(''input'', %d, ''Goal'');',maskDisplayText, inPort);
            inPort = 2;
            maskDisplayText = sprintf('%s\nport_label(''input'', %d, ''Enable'');',maskDisplayText, inPort);

            outPort = 1;
            maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''UUID'');',maskDisplayText, outPort);
            if isequal(get_param(block, 'ShowErrorCodeOutput'), 'on')
                outPort = outPort + 1;
                maskDisplayText = sprintf('%s\nport_label(''output'', %d, ''ErrorCode'');',maskDisplayText, outPort);
            end

            % Set the block mask display and icon
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            ros.internal.setBlockIcon(blkH, 'rosicons.ros2lib_sendActionGoal');

            obj.messageLoadFcn(block);
        end

        function qosHistorySelect(~, block, QoSType)
            maskEnables = get_param(block,'MaskVisibilities');
            maskObj = Simulink.Mask.get(block);
            qosDepthIdx = arrayfun(@(x)isequal(x.Name, [QoSType 'QoSDepth']),maskObj.Parameters);
            if isequal(get_param(block,[QoSType 'QoSHistory']), message('ros:slros2:blockmask:QOSKeepAll').getString)
                maskEnables{qosDepthIdx} = 'off';
            else
                maskEnables{qosDepthIdx} = 'on';
            end
            set_param(block,'MaskVisibilities',maskEnables);
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
            ret = 'ROS 2 Send Action Goal';
        end

        function messageLoadFcn(block)
            if ~ros.slros.internal.block.CommonActionMask.isLibraryBlock(block)
                actionType = get_param(block,'actionType');
                ros.slros2.internal.bus.Util.createBusIfNeeded(strcat(actionType,'Goal'),bdroot(block));
                ros.slros2.internal.bus.Util.createBusIfNeeded('unique_identifier_msgs/UUID',bdroot(block));
            end
        end

        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros2.internal.block.SendActionGoalBlockMask;
            obj.(methodName)(varargin{:});
        end
    end
end
