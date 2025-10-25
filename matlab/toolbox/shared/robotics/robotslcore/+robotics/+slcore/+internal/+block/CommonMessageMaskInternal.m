classdef (Abstract) CommonMessageMaskInternal < robotics.slcore.internal.block.CommonMaskInternal
%CommonMessageMaskInternal Common base class for Gazebo message producers and consumers
%   This class is used only for Gazebo Co-Simulation Simulink blocks. In particular,
%   this includes Gazebo read, Gazebo Apply, Gazebo Blank Message, Gazebo
%   Subscribe and Gazebo Publish blocks.

%   Copyright 2019-2020 The MathWorks, Inc.

    properties(Abstract, Constant)

        %TopicSelectorDlg Select the topic dialog generation object
        TopicSelectorDlg

        %MsgTypeSelectorDlg Select the message type dialog generation object
        MsgTypeSelectorDlg

    end


    methods
        %% Block InitFcns

        % Callbacks for individual params are invoked when:
        % * User opens a mask dialog
        % * User modifies a param value and changes focus
        % * User modifies a param value and selects OK or Apply
        % * The model is updated (user presses Ctrl+D or simulates the model)

        function constantBlkInitFcn(obj, constantBlk, busNamePrefix, msgPackageName)

            block = get_param(constantBlk, 'parent');
            msgType = get_param(block, 'messageType');

            obj.BusUtil.BusNamePrefix = busNamePrefix;
            obj.BusUtil.MsgPackageName = msgPackageName;
            obj.BusUtil.createBusIfNeeded(msgType, bdroot(constantBlk));
        end

        function sysobjInitFcn(obj, sysobjBlock)
            msgType = get_param(sysobjBlock, obj.SourceBlkMsgType);
            expectedBusName = obj.BusUtil.messageTypeToBusName(msgType, bdroot(sysobjBlock), obj.BusUtil.BusNamePrefix);

            currentBusName = get_param(sysobjBlock, 'OutputBusName');
            if ~strcmp(currentBusName, expectedBusName)
                % Do not mark the model dirty when the Simulink bus name
                % is updated on the underlying mask of Simulink Gazebo I/O
                % blocks.
                % All changes to model is ignored when this
                % "preserveDirty" variable is in Scope, hence this only
                % encompasses the set_param call in this if-else section.
                preserveDirty = Simulink.PreserveDirtyFlag(bdroot(sysobjBlock),'blockDiagram');  %#ok<NASGU>
                set_param(sysobjBlock, 'OutputBusName', expectedBusName);
            end
        end
    end

    %%
    methods
        %% Callbacks
        % Callbacks for individual params are invoked when the user:
        % * Opens a mask dialog
        % * Modifies a param value and changes focus
        % * Modifies a param value and selects OK or Apply
        % * Updates the model (presses Ctrl+D or simulates the model)
        %
        % Note - these are **not** invoked when user does a SET_PARAM

        function topicSourceSelect(obj, block)
            maskValues = get_param(block, 'MaskValues');
            maskVisibilities = get_param(block, 'MaskVisibilities');
            maskEnables = get_param(gcb,'MaskEnables');

            mask = Simulink.Mask.get(block);
            dlg = mask.getDialogControls;

            d = obj.MaskDlgIndex.TopicSelect;
            m = obj.MaskDlgIndex.MessageTypeSelect;

            if strcmpi(maskValues{obj.MaskParamIndex.TopicSourceDropdown}, obj.TopicSourceSpecifyOwn)
                % Custom topic
                % Enable editing of topic
                maskEnables{obj.MaskParamIndex.TopicEdit} = 'on';
                % Hide Topic selection button
                dlg(d(1)).DialogControls(d(2)).DialogControls(d(3)).Visible = 'off';
                % Show MessageType selection button
                dlg(m(1)).DialogControls(m(2)).DialogControls(m(3)).Visible = 'on';
            else % select topic from Gazebo network
                 % Disable editing of topic
                maskEnables{obj.MaskParamIndex.TopicEdit} = 'off';
                % Show Topic selection button
                dlg(d(1)).DialogControls(d(2)).DialogControls(d(3)).Visible = 'on';
                % Hide MessageType selection button
                dlg(m(1)).DialogControls(m(2)).DialogControls(m(3)).Visible = 'off';
            end

            set_param(gcb,'MaskEnables', maskEnables);
            set_param(gcb,'MaskVisibilities', maskVisibilities);
        end

        % When the user updates the message type and/or topic, updateSubsystem
        % has be called in a callback context (since it is modifying the block).
        %
        % However, topicSelect() and messageTypeSelect() cannot call
        % updateSubsystem as the dialog is still open when the function is
        % done (the user hasn't made the selection yet). So topicSelect and
        % messageTypeSelect will return without applying any changes.
        % Note - we can't pass around a handle to updateSubsystem  as it
        % can only be called from within the callback context.
        %
        % Solution:
        %   Ensure either topicEdit() or messageTypeEdit() callbacks are
        %   configured. Once the user applies the change by clicking on OK/Apply
        %   in the mask dialog, the maskInitialize() will be invoked, and
        %   also the callbacks will be called on the next model update, so these
        %   will invoke updateSubsystem().
        %
        % The above solution also ensures that the pub and sub block
        % subsystems will be updated correctly if the user modifies the
        % 'topic' or 'messageType' parameters using SET_PARAM (since
        % the mask callbacks will be invoked during model update)

        function topicEdit(obj, block, varargin)

            msgType = get_param(block, 'messageType');
            obj.BusUtil.BusNamePrefix = varargin{1};%busNamePrefix;
            obj.BusUtil.MsgPackageName = varargin{2};%msgPackageName;
            obj.BusUtil.createBusIfNeeded(msgType, bdroot(block));

            obj.updateSubsystem(block);
        end

        function messageTypeEdit(obj, block, varargin)
            msgType = get_param(block, 'messageType');

            obj.BusUtil.BusNamePrefix = varargin{1};
            obj.BusUtil.MsgPackageName = varargin{2};
            obj.BusUtil.createBusIfNeeded(msgType, bdroot(block));

            obj.updateSubsystem(block);
        end

        function topicSelect(obj, block)
            try
                %msgDlg = robotics.slgazebo.internal.dlg.TopicSelectorGazebo();
                msgDlg = obj.TopicSelectorDlg;
                msgDlg.openDialog(@dialogCloseCallback);
            catch ME
                % Send error to Simulink diagnostic viewer rather than a
                % DDG dialog.
                % NOTE: This does NOT stop execution.
                reportAsError(MSLDiagnostic(ME));
            end

            function dialogCloseCallback(isAcceptedSelection, selectedTopic, selectedMsgType)
                if isAcceptedSelection
                    set_param(block, 'topic', selectedTopic);
                    set_param(block, 'messageType', selectedMsgType);
                end
            end
        end

        function messageTypeSelect(obj, block)
            currentMsgType = get_param(block, 'messageType');

            %msgDlg = robotics.slgazebo.internal.dlg.MessageTypeSelector();
            msgDlg = obj.MsgTypeSelectorDlg;
            msgDlg.openDialog(currentMsgType, @dialogCloseCallback);

            function dialogCloseCallback(isAcceptedSelection, selectedMsg)
                if isAcceptedSelection
                    set_param(block, 'messageType', selectedMsg);
                end
            end
        end

    end
end
