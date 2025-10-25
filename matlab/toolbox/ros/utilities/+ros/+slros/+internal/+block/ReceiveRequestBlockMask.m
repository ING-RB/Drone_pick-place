classdef ReceiveRequestBlockMask < ros.slros.internal.block.CommonServiceMask
%This class is for internal use only. It may be removed in the future.

%ReceiveRequestBlockMask - Block mask for Receive Request block

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        %DefaultRespSinkName - Name of sink block for DefaultResponse
        %   In practice, this block is either a terminator (if user does
        %   not want the output) or a standard outport.
        DefaultRespSinkName = 'DefaultResponse'
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
                pairedBlkLnk.Prompt = 'ros:slros2:blockmask:NoSvcPairedBlkPrompt';
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
        end

        function updateBlockIcon(~, blkH)
            ros.internal.setBlockIcon(blkH, 'rosicons.robotlib_callservice');
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
            service = get_param(block, 'service');
            serviceType = get_param(block, 'serviceType');

            % Reuse existed functionality
            %  * inputBusDataType - request message bus data type
            %  * slInputBusName - request message bus name
            %  * outputBusDataType - response message bus data type
            %  * slOutputBusName - response message bus name
            [~,slInputBusName, ~, ~] = ...
                ros.slros.internal.bus.Util.rosServiceTypeToDataTypeStr(rosServiceType, bdroot(block));

            % note: we use the block id of the parent, not the sys_obj
            % block
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'ServRec_');
            modelName = bdroot(block);

            set_param(sysobjBlock, 'SLBusName', slInputBusName);
            set_param(sysobjBlock, 'ServiceType', serviceType);
            set_param(sysobjBlock, 'ServiceName', service);
            set_param(sysobjBlock, 'ModelName', modelName);
            set_param(sysobjBlock, 'BlockId', blockId);
            set_param(reqBlankBlock, 'entityType', serviceType);
            set_param(respBlankBlock, 'entityType', serviceType);
        end
    end

    methods (Static)
        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros.internal.block.ReceiveRequestBlockMask;
            obj.(methodName)(varargin{:});
        end
    end
end