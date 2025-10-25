classdef ApplyTransformBlockMask
%This class is for internal use only. It may be removed in the future.

%ApplyTransformBlockMask - Block mask callbacks for ROS Apply Transform
%block

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve this with get_param(gcb,'MaskType')
        MaskType = 'ros.slroscpp.internal.block.ApplyTransform'

        %SysObjBlockName - System object block name
        SysObjBlockName = 'ApplyTransform'

        %EntitySignalBlk1 - Signal Specification block name for entity port
        EntitySignalBlk1 = 'SignalSpecification1'

        %EntitySignalBlk - Signal Specification block name for TFMsg port
        EntitySignalBlk = 'SignalSpecification'
    end

    methods
        function maskInitialize(obj, block)
        %maskInitialize Initialize the block mask
            updateIconAndBuses(obj,block);
            updateSubsystem(obj,block);
            entityMsgTypeSelect(obj, block);
        end

        function entityMsgTypeSelect(obj, block)
        %entityMsgTypeSelect Update bus type for blocks under subsystem

            entityMsgType = get_param(block, 'EntityMsgType');
            [entityBusName,~] = ros.slros.internal.bus.Util.rosMsgTypeToDataTypeStr(entityMsgType, bdroot(block));
            entity_sig_blk = [block '/' obj.EntitySignalBlk1];
            set_param(entity_sig_blk,'OutDataTypeStr',entityBusName);
        end

        function updateIconAndBuses(obj, block)
        %updateIconAndBuses updates icon and Simulink buses
            % Causes the icon to be redrawn
            blkH = get_param(block,'handle');
            maskDisplayText = sprintf('color(''black'');');
            maskDisplayText = sprintf('%s\nport_label(''input'', 1, ''TFMsg'');',maskDisplayText);
            maskDisplayText = sprintf('%s\nport_label(''input'', 2, ''Entity'');',maskDisplayText);
            maskDisplayText = sprintf('%s\nport_label(''output'', 1, ''TFEntity'');',maskDisplayText);
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            ros.internal.setBlockIcon(blkH, 'rosicons.robotlib_applytransform');

            obj.messageLoadFcn(block);
            [tfBusName,~] = ros.slros.internal.bus.Util.rosMsgTypeToDataTypeStr('geometry_msgs/TransformStamped', bdroot(block));
            tf_sig_blk = [block '/' obj.EntitySignalBlk];
            set_param(tf_sig_blk,'OutDataTypeStr',tfBusName);

            % Update system object output bus name
            sysobj_block = [block '/' obj.SysObjBlockName];
            entityMsgType = get_param(block, 'EntityMsgType');
            [~,entityMsgName] = ros.slroscpp.internal.bus.Util.rosMsgTypeToDataTypeStr(entityMsgType,bdroot(block));
            set_param(sysobj_block, 'SLOutputBusName', entityMsgName);
        end

        function updateSubsystem(obj,block)
        %updateSubsystem updates subsystem ModelName and BlockId
            
            sysobj_block = [block '/' obj.SysObjBlockName];
            modelName = bdroot(block);
            set_param(sysobj_block,'ModelName',modelName);

            % note: we use the block id of the parent, not the sys_obj
            % block
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'APTF_');
            set_param(sysobj_block, 'BlockId', blockId);
        end

        function modelCloseFcn(~, block)
        %modelCloseFcn Called when the model is closed

        % Avoid clearing buses when library is closed
        % (prevents clearing when library unloaded on simulation)
            ros.slros.internal.bus.clearBusesOnModelClose(block);
        end
    end

    methods(Static)
        function messageLoadFcn(block)
            entityMsgType = get_param(block,'EntityMsgType');
            if ~ros.slros.internal.block.CommonMask.isLibraryBlock(block)
                ros.slroscpp.internal.bus.Util.createBusIfNeeded(entityMsgType,bdroot(block));
                ros.slroscpp.internal.bus.Util.createBusIfNeeded('geometry_msgs/TransformStamped',bdroot(block));
            end
        end

        function dispatch(methodName, varargin)
        %dispatch Dispatch to static methods in this class
            obj = ros.slros.internal.block.ApplyTransformBlockMask;
            obj.(methodName)(varargin{:});
        end
    end
end
