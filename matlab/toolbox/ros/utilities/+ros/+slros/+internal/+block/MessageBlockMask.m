classdef MessageBlockMask < ros.slros.internal.block.CommonMessageMask
%This class is for internal use only. It may be removed in the future.

%MessageBlockMask - Block mask callbacks for "Blank Message" block

%   Copyright 2014-2023 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'ROS Blank Message'

        MaskParamIndex = struct( ...
            'MessageSelect', 1)

        MaskDlgIndex = struct( ...
            'MessageTypeSelect', [2 3] ... % Parameters Container > Msg Select Button
            )

        SysObjBlockName = ''  % No system object block
    end

    properties (Constant)
        %MessageClassMap - Possible settings for the message class
        %   The keys of the map are the selections of the messageClass
        %   dropdown on the blockmask.
        %   Each value is an entity type (message type or service type or action type)
        MessageClassMap = containers.Map(...
            {'Message', 'Service Request', 'Service Response', ...
            'Action Feedback', 'Action Goal', 'Action Result'}, ...
            {'geometry_msgs/Point', 'std_srvs/Empty', 'std_srvs/Empty', ...
            'example_interfaces/Fibonacci', 'example_interfaces/Fibonacci', 'example_interfaces/Fibonacci'})
    end


    methods
        function messageClassChange(obj, block)
            %messageClassChange The message class dropdown changed

            % If current entity type is compatible with the selected message class,
            % don't change it

            msgList = rostype.getMessageList();
            srvList = rostype.getServiceList();
            actList = rostype.getActionList();
            if obj.isEntityTypeCompatible(block,msgList,srvList,actList)
                obj.setMessageTypeBasedOnEntity(block);
                return;
            end

            msgClass = get_param(block, 'messageClass');
            if isKey(obj.MessageClassMap, msgClass)
                entityType = obj.MessageClassMap(msgClass);

                % Set entity type
                set_param(block, 'entityType', entityType)
                obj.setMessageTypeBasedOnEntity(block);
            end
        end

        function entityTypeEdit(obj, block)
        %entityTypeEdit Update buses and subsystem based on entity type selection

            obj.setMessageTypeBasedOnEntity(block);
            obj.updateSubsystem(block);
        end

        function updateSubsystem(~, block)
        %updateSubsystem Update the constant block in subsystem

            msgType = get_param(block, 'messageType');
            constantBlock = [block '/Constant'];

            busDataType = ros.slros.internal.bus.Util.rosMsgTypeToDataTypeStr(msgType, bdroot(block));
            set_param(constantBlock, 'OutDataTypeStr', busDataType);
        end

        function selectButtonPressed(obj, block)
        %selectButtonPressed Callback for "Select" button
        %   This brings up either the message type selection dialog or
        %   the service type selection dialog.

            if obj.isServiceClass(block)
                % Configure a service type selection dialog
                header = message('ros:slros:svcselector:ServiceTypeDialogHeader').string;
                title = message('ros:slros:svcselector:ServiceTypeDialogTitle').getString;
                helpId = "rosServiceTypeSelectDlg";
                typeList = rostype.getServiceList;
            else
                % Configure a message type selection dialog
                header = message('ros:slros:msgselector:DialogHeader').string;
                title = message('ros:slros:msgselector:DialogTitle').getString;
                helpId = "rosMsgSelectDlg";
                typeList = ros.slros.internal.ROSUtil.getMessageTypesWithoutServices;
            end

            % Bring up the dialog
            dlg = ros.slros.internal.dlg.TableViewer(...
                header, ...
                "Title", title, ...
                "HelpMethod", "ros.slros.internal.helpview", ...
                "HelpId", helpId, ...
                "HeaderVisibility", [0 0], ...
                "LastColumnStretchable", true, ...
                "DialogSize", [400,400] ...
                );

            % Select the correct row
            entityType = get_param(block, 'entityType');
            [isTypeInList, listIdx] = ismember(entityType, typeList);

            if isTypeInList
                dlg.InitialRowSelection = listIdx;
            end

            dlg.updateData(table(typeList));
            dlg.openDialog(@dialogCloseCallback);

            function dialogCloseCallback(isAcceptedSelection, selectedRow)
                if isAcceptedSelection
                    set_param(block, 'entityType', selectedRow.typeList{1});
                    setMessageTypeBasedOnEntity(obj, block);
                end
            end
        end

        function loadFcn(obj, block)
            %loadFcn Verify consistency of parameters when LoadFcn is called
            %   This function is primarily used to ensure
            %   backwards-compatibility.
                        
            entityType = get_param(block, 'entityType');
            msgType = get_param(block, 'messageType');
            msgClass = get_param(block, 'messageClass');

            expectedMsgType = obj.entityToMessageType(entityType, msgClass);

            if ~strcmp(msgType, expectedMsgType)
                % This block was likely saved before the entityType was
                % introduced. Set it accordingly.
                set_param(block, 'entityType', msgType);
            end
        end

        function preSaveFcn(obj, block)
        %preSaveFcn Verify consistency of parameters before saving

            if ~obj.isLibraryBlock(block)
                obj.setMessageTypeBasedOnEntity(block);
            end
        end
        
        function maskInitialize(obj, block)
            blkH = get_param(block, 'handle');
            entityType = get_param(block,'entityType');
            msgClass = get_param(block, 'messageClass');
            messageType = obj.entityToMessageType(entityType,msgClass);
            maskDisplayText = sprintf('color(''black'');');
            if ~obj.isLibraryBlock(block)
                if length(messageType) > 16
                    maskDisplayText = sprintf('%s\ntext(0.83, 0.15, ''%s'', ''horizontalAlignment'', ''right'');', ...
                        maskDisplayText, messageType);
                else
                    maskDisplayText = sprintf('%s\ntext(0.45, 0.15, ''%s'', ''horizontalAlignment'', ''center'');', ...
                        maskDisplayText, messageType);
                end
            end
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            ros.internal.setBlockIcon(blkH, 'rosicons.robotlib_blankmessage');
        end        
    end

    methods (Access = {?ros.slros.internal.block.MessageBlockMask,?ros.slros2.internal.block.MessageBlockMask})
        function setMessageTypeBasedOnEntity(obj, block)
        %setMessageTypeBasedOnEntity Set message type based on entity type
        %   For example, when dealing with services, we have to attach
        %   "Request" or "Response".

            entityType = get_param(block, 'entityType');
            msgClass = get_param(block, 'messageClass');

            msgType = obj.entityToMessageType(entityType, msgClass);

            % Update buses and subsystem
            set_param(block, 'messageType', msgType);
            ros.slroscpp.internal.bus.Util.createBusIfNeeded(msgType, bdroot(block));
        end

        function msgType = entityToMessageType(~, entityType, msgClass)
        %entityToMessageType Convert entity type to message type

            msgClass = string(msgClass);

            if msgClass.startsWith("Action")
                % This is a action entity
                if msgClass.endsWith("Feedback")
                    msgType = strcat(entityType, 'Feedback');
                elseif msgClass.endsWith("Goal")
                    msgType = strcat(entityType, 'Goal');
                else
                    msgType = strcat(entityType, 'Result');
                end
            elseif msgClass.startsWith("Service")
                % This is a service entity
                if msgClass.endsWith("Request")
                    msgType = strcat(entityType, 'Request');
                else
                    msgType = strcat(entityType, 'Response');
                end
            else
                % This is a message entity
                msgType = entityType;
            end
        end
    end

    methods (Static,Access = {?ros.slros.internal.block.MessageBlockMask,?ros.slros2.internal.block.MessageBlockMask})
        function isMessage = isMessageClass(block)
        %isServiceClass Determine if a service is selected

            msgClass = string(get_param(block, 'messageClass'));
            isMessage = msgClass.startsWith("Message");
        end

        function isService = isServiceClass(block)
        %isServiceClass Determine if a service is selected

            msgClass = string(get_param(block, 'messageClass'));
            isService = msgClass.startsWith("Service");
        end

        function isAction = isActionClass(block)
        %isActionClass Determine if a action is selected

            msgClass = string(get_param(block, 'messageClass'));
            isAction = msgClass.startsWith("Action");
        end

        function isCompatible = isEntityTypeCompatible(block,msgList,srvList,actList)
        %isEntityTypeCompatible Verify if entity type is compatible with selected message class
        %   The scenario is that the user changed the message class
        %   setting, e.g. to "Service Request", but if the selected
        %   "Type" is compatible with the new message class, we should
        %   not overwrite it.

            isMessage = ros.slros.internal.block.MessageBlockMask.isMessageClass(block);
            isService = ros.slros.internal.block.MessageBlockMask.isServiceClass(block);
            isAction = ros.slros.internal.block.MessageBlockMask.isActionClass(block);

            entityType = get_param(block, 'entityType');
            % Service type message should have a corresponding request and
            % response message. If these messages do not exist, then this
            % is a normal message
            if isService
                isEntityAServiceType = ismember(entityType, srvList);
                isCompatible = isService == isEntityAServiceType;
            elseif isAction
                % Action type message should have a corresponding goal, feedback and
                % result message. If these messages do not exist, then this
                % is a normal message
                isEntityAnActionType = ismember(entityType, actList);
                isCompatible = isAction == isEntityAnActionType;
            else
                isEntityAnMessageType = ismember(entityType, msgList);
                isCompatible = isMessage == isEntityAnMessageType;
            end
        end
    end

    methods (Static)

        function dispatch(methodName, varargin)
            obj = ros.slros.internal.block.MessageBlockMask();
            obj.(methodName)(varargin{:});
        end

    end
end


