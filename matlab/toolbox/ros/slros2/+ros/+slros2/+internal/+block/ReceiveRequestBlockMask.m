classdef ReceiveRequestBlockMask < ros.slros.internal.block.CommonServiceMask
%This class is for internal use only. It may be removed in the future.

%ReceiveRequestBlockMask - Block mask for Receive Request block

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        MaskType = 'ROS2 Receive Service Request'

        %DefaultRespSinkName - Name of sink block for DefaultResponse
        %   In practice, this block is either a terminator (if user does
        %   not want the output) or a standard outport.
        DefaultRespSinkName = 'DefaultResponse'

        %DefaultPrompt - Default prompt for hyperlink text
        DefaultPrompt = 'ros:slros2:blockmask:NoSendResponsePairedBlkPrompt'
    end
    
    properties (Constant)
        %% Abstract properties inherited from CommonMask base class
        MaskParamIndex = struct( ...
            'ServiceNameEdit', 1, ...
            'ServiceTypeEdit', 2 ...
            );

        MaskDlgIndex = struct( ...
            'ServiceTypeSelect', [2 3] ...    % Service Group Box > Service Type Select Button
            );

        SysObjBlockName = 'SvcReceiverObj';
    end
    
    methods
        function serviceEdit(obj, block)
        %serviceEdit - Callback when service name changes

            sysobj_block = [block '/' obj.SysObjBlockName];
            curValue = get_param(sysobj_block, 'ServiceName');
            newValue = get_param(block, 'service');

            % Check for validity and make sure that the name is a valid ROS
            % 2 name
            if ~ros.internal.Namespace.isValidGraphName(newValue)
                set_param(block, 'service', curValue);
                error(message('ros:slros:svccaller:InvalidServiceName', newValue));
            end

            % Update paired block if exists
            obj.updatePairedBlkMaskParam(block, 'service', newValue);
            obj.messageLoadFcn(block);
            obj.updateSubsystem(block);
        end

        function serviceTypeSelect(obj, block, getDlgFcn)
        %serviceTypeSelect Callback for "Select" button on service type

            currentServiceType = get_param(block, 'serviceType');

            svcDlg = feval(getDlgFcn);
            svcDlg.openDialog(currentServiceType, @dialogCloseCallback);

            function dialogCloseCallback(isAcceptedSelection, selectedSvc)
                if isAcceptedSelection
                    set_param(block, 'serviceType', selectedSvc);
                    ros.slros2.internal.block.ReceiveRequestBlockMask.clearServer(block);
                    obj.updatePairedBlkMaskParam(block, 'serviceType', selectedSvc);
                end
            end
        end

        function updatePairedBlkMaskParam(obj, block, maskParam, paramValue)
        %updatePairedBlkMaskParam Updates paired block (if exists) mask parameter

            pairBlkMgr = ros.internal.block.PairedBlockManager.getInstance;
            currBlkH = getSimulinkBlockHandle(block);
            pairedBlkH = pairBlkMgr.getPairedBlock(currBlkH);
            if pairedBlkH
                set_param(pairedBlkH,maskParam,paramValue);
                pairBlkMgr.updatePairedBlkHyperlink(currBlkH, obj.DefaultPrompt);
            end
        end

        function maskInitialize(obj, block)
        %maskInitialize Mask Initialization callback
        %   It is invoked when the user:
        %   * Changes the value of a mask parameter by using the block dialog box or set_param.
        %   * Changes any of the parameters that define the mask
        %   * Causes the icon to be redrawn
        %   * Copies the block
        %
        %   Mask initialization is invoked after the individual parameter
        %   callbacks

            % Show or hide the Default Response output port
            showDefaultResponse = get_param(block, 'ShowDefaultRespOutput');

            % existingRespSink is the sink block for the DefaultResponse
            % output in the current subsystem. This can either be a
            % standard outport, or a terminator.
            existingRespSink = [block '/' obj.DefaultRespSinkName];

            % Determine what type the sink block should be based on the
            % checkbox setting on the mask.
            if strcmp(showDefaultResponse, 'on')
                newRespSink = sprintf('built-in/Outport');
            else
                newRespSink = sprintf('built-in/Terminator');
            end

            % Only modify the subsystem if new block type is different
            existingOutportType = get_param(existingRespSink, 'BlockType');
            newOutportType = get_param(newRespSink, 'BlockType');
            if ~strcmp(existingOutportType, newOutportType)
                % Preserve orientation and position to ensure that the
                % existing signal line connects without any issues.
                orient = get_param(existingRespSink, 'Orientation');
                pos = get_param(existingRespSink, 'Position');
                delete_block(existingRespSink);
                add_block(newRespSink, existingRespSink, ...
                            'Name', obj.DefaultRespSinkName, ...
                            'Orientation', orient, ...
                            'Position', pos);
            end

            if ~strcmp(bdroot(block),'ros2lib')
                % Update mask and paired block
                [foundPairedBlk, blkH, ~] = ros.slros.internal.ROSUtil.getMatchingServerBlkByService(block,'service');
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

            % Set block mask display
            blkH = get_param(block, 'handle');
            serviceName = get_param(block, 'service');
            maskDisplayText = sprintf('color(''black'');');
            if length(serviceName) > 20
                maskDisplayText = sprintf('%s\ntext(0.95, 0.15, ''%s'', ''horizontalAlignment'', ''right'');', ...
                    maskDisplayText, serviceName);
            else
                maskDisplayText = sprintf('%s\ntext(0.5, 0.15, ''%s'', ''horizontalAlignment'', ''center'');', ...
                    maskDisplayText, serviceName);
            end
            maskDisplayText = sprintf('%s\nport_label(''output'', 1, ''IsNew'');',maskDisplayText);
            maskDisplayText = sprintf('%s\nport_label(''output'', 2, ''Req'');',maskDisplayText); 
            if strcmp(showDefaultResponse, 'on')
                maskDisplayText = sprintf('%s\nport_label(''output'', 3, ''DefaultResp'');',maskDisplayText); 
            end
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            obj.updateBlockIcon(blkH);
            obj.messageLoadFcn(block);
            obj.updateSubsystem(block);

            % Set blockId in maskInitialization in case users updates the
            % model before opening the mask.
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'ServRec_');
            set_param(block, 'BlockId', blockId);
        end

        function updateSubsystem(obj, block)
        %updateSubsystem Callback executed on subsystem update

        % There are 3 blocks in the subsystem that need to be updated:
        %  * The MATLAB System block with name SvcReceiverObj
        %  * The Blank Message for Request
        %  * The Blank Message for Response
            sysobjBlock = [block '/' obj.SysObjBlockName];
            reqBlankBlock = [block '/Blank Message'];
            respBlankBlock = [block '/Blank Message1'];

            % Do not canonicalize the service name (i.e., if user entered
            % "foo", don't convert it to "/foo"). This enables user to
            % control whether to have a relative or absolute service name in
            % generated code.
            serviceType = get_param(block, 'serviceType');

            % Reuse existed functionality
            %  * inputBusDataType - request message bus data type
            %  * slInputBusName - request message bus name
            %  * outputBusDataType - response message bus data type
            %  * slOutputBusName - response message bus name
            [~,slInputBusName, ~, ~] = ...
                ros.slros2.internal.bus.Util.rosServiceTypeToDataTypeStr(serviceType);

            % note: we use the block id of the parent, not the sys_obj
            % block
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'ServRec_');
            modelName = bdroot(block);

            set_param(sysobjBlock, 'SLBusName', slInputBusName);
            set_param(sysobjBlock, 'ModelName', modelName);
            set_param(block, 'BlockId', blockId);
            set_param(reqBlankBlock, 'entityType', serviceType);
            set_param(respBlankBlock, 'entityType', serviceType);
        end

        function copyBlockInit(obj,block)
        %copyBlockInit Mask initialization for copy block
        %   This function helps the new copied block to find potential
        %   paring block and setup parameters.

            ros.slros.internal.ROSUtil.copyBlkCallback(block,'service', obj.DefaultPrompt);
        end

        function deleteFcnCallback(~,block)
        %deleteFcnCallback Mask callback for deleteFcn
        %   This function removes the pairing and clear the service server
        %   object when model is closed or block is deleted

            ros.slros.internal.ROSUtil.removeBlkPairingRegistration(block);
            ros.slros2.internal.block.ReceiveRequestBlockMask.clearServer(block);
        end

        function updateBlockIcon(~, blkH)
            ros.internal.setBlockIcon(blkH, 'rosicons.ros2lib_receiveRequest');
        end
    end

    methods (Static)
        function ret = getMaskType()
            ret = 'ROS2 Receive Service Request';
        end
        
        function messageLoadFcn(block)
            if ~ros.slros.internal.block.CommonMask.isLibraryBlock(block)
                serviceType = get_param(block,'serviceType');
                ros.slros2.internal.bus.Util.createBusIfNeeded(strcat(serviceType,'Request'),bdroot(block));
                ros.slros2.internal.bus.Util.createBusIfNeeded(strcat(serviceType,'Response'),bdroot(block));
            end
        end

        function qosCell = getQOSSettings(block)
        %getQOSSettings Generate QOS cell array associated with the block

            qosCell = {'History', lower(regexprep(get_param(block,'QOSHistory'), '\s','')), ...
                       'Depth', str2num(get_param(block,'QOSDepth')), ...
                       'Reliability', lower(regexprep(get_param(block,'QOSReliability'), '\s','')), ...
                       'Durability', lower(regexprep(get_param(block,'QOSDurability'), '\s','')), ...
                       'Deadline', str2num(get_param(block,'QOSDeadline')), ...
                       'Lifespan', str2num(get_param(block,'QOSLifespan')), ...
                       'Liveliness', lower(regexprep(get_param(block,'QOSLiveliness'), '\s','')), ...
                       'LeaseDuration', str2num(get_param(block,'QOSLeaseDuration')), ...
                       'AvoidROSNamespaceConventions', ~strcmp(get_param(block,'QOSAvoidROSNamespaceConventions'),'off')}; %#ok<*ST2NM>
        end

        function initializeServer(block)
        %InitializeServer Initialize service server to Simulink workspace

            if ~strcmp(bdroot(block),'ros2lib')
                % Get server properties from block mask
                service = get_param(block, 'service');
                serviceType = get_param(block, 'serviceType');
    
                % Use block id to create unique server variable name
                sysobjBlock = [block '/SvcReceiverObj'];
                serverVarName = get_param(sysobjBlock, 'BlockId');
    
                % Get qos settings from block
                qosArgsCell = ros.slros2.internal.block.ReceiveRequestBlockMask.getQOSSettings(block);
    
                % Get model state node
                modelState = ros.slros.internal.sim.ModelStateManager.getState(bdroot, 'create');
                if isempty(modelState.ROSNode) || ~isValidNode(modelState.ROSNode)
                    uniqueName = [bdroot(block) '_' num2str(randi(1e5,1))];
                    modelState.ROSNode = ros2node(uniqueName, ...
                                                  ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink, ...
                                                  'RMWImplementation', ...
                                                  ros.ros2.internal.NetworkIntrospection.getRMWImplementationForSimulink);
                end

                % Create service server and save in dictionary under
                % singleton SharedObjectManager
                mgr = ros.internal.block.SharedObjectManager.getInstance;
                mgr.addSvcServer(serverVarName, modelState.ROSNode, ...
                                 service, serviceType, qosArgsCell);
            end
        end

        function clearServer(block)
        %clearServer Clear server object from Simulink workspace

            % Clear variable from Simulink workspace
            if ~strcmp(bdroot(block),'ros2lib')
                % Remove service server from dictionary
                sysobjBlock = [block '/SvcReceiverObj'];
                serverVarName = get_param(sysobjBlock, 'BlockId');
                mgr = ros.internal.block.SharedObjectManager.getInstance;
                mgr.removeSvcServer(serverVarName);

                ros.slros.internal.sim.ModelStateManager.clearAll();
            end
        end

        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros2.internal.block.ReceiveRequestBlockMask;
            obj.(methodName)(varargin{:});
        end
    end
end
