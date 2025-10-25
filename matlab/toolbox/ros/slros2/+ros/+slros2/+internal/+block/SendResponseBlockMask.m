classdef SendResponseBlockMask < ros.slros.internal.block.SendResponseBlockMask
%This class is for internal use only. It may be removed in the future.

%SendResponseBlockMask - Block mask for Send Response block.

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        MaskType = 'ROS2 Send Service Response'

        %DefaultPrompt - Default prompt for hyperlink text
        DefaultPrompt = 'ros:slros2:blockmask:NoReceiveRequestPairedBlkPrompt'
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
        
            blkH = get_param(block, 'handle');
            if ~strcmp(bdroot(block),'ros2lib')
                % Update mask and paired block
                [foundPairedBlk, pairedBlkH, ~] = ros.slros.internal.ROSUtil.getMatchingServerBlkByService(block,'service');
                if foundPairedBlk
                    % set BlockId and serviceType retrieved from paired
                    % block. 
                    % There is no need to set hyperlink since it has been
                    % set when finding paired block.
                    set_param(blkH,'BlockId',get_param(pairedBlkH,'BlockId'));
                    set_param(blkH,'serviceType',get_param(pairedBlkH,'serviceType'));
                end
            end
            
            % Set block mask display
            serviceName = get_param(block, 'service');
            maskDisplayText = sprintf('color(''black'');');
            if length(serviceName) > 20
                maskDisplayText = sprintf('%s\ntext(0.95, 0.15, ''%s'', ''horizontalAlignment'', ''right'');', ...
                    maskDisplayText, serviceName);
            else
                maskDisplayText = sprintf('%s\ntext(0.5, 0.15, ''%s'', ''horizontalAlignment'', ''center'');', ...
                    maskDisplayText, serviceName);
            end
            maskDisplayText = sprintf('%s\nport_label(''input'', 1, ''Resp'');',maskDisplayText);
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            obj.updateBlockIcon(blkH);
        end

        function copyBlockInit(obj,block)
        %copyBlockInit Mask initialization for copy block
        %   This function helps the new copied block to find potential
        %   paring block and setup parameters.

            ros.slros.internal.ROSUtil.copyBlkCallback(block,'service', obj.DefaultPrompt);
        end

        function updateBlockIcon(~, blkH)
            ros.internal.setBlockIcon(blkH, 'rosicons.ros2lib_sendResponse');
        end

        function updateSubsystem(obj, block)
        %updateSubsystem Callback executed on subsystem update

            sysobjBlock = [block '/' obj.SysObjBlockName];
            sigspec_block = [block '/SignalSpecification'];

            serviceType = get_param(block, 'serviceType');
            [~,~,busDataType, ~] = ros.slros2.internal.bus.Util.rosServiceTypeToDataTypeStr(serviceType);

            modelName = bdroot(block);
            set_param(sysobjBlock, 'ModelName', modelName);
            set_param(sigspec_block, 'OutDataTypeStr', busDataType);

            obj.maskInitialize(block);
        end
    end

    methods (Static)
        function ret = getMaskType()
            ret = 'ROS2 Send Service Response';
        end

        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros2.internal.block.SendResponseBlockMask;
            obj.(methodName)(varargin{:});
        end
    end
end