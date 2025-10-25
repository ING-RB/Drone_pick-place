classdef GetTransformBlockMask < ros.slros.internal.block.CommonMask
%This class is for internal use only. It may be removed in the future.

%GetTransformBlockMask - Block mask callbacks for Get Transform block

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'ros.slroscpp.internal.block.GetTransform'
    end

    properties (Constant)
        MaskParamIndex = struct( ...
            'FrameSourceDropdown',1, ...
            'TargetFrameEdit', 2, ...
            'SourceFrameEdit', 3 ...
            );

        MaskDlgIndex = struct( ...
            'TargetFrameSelect', [2 1 3], ... % Tab Container > "Main" tab > "Param Group" > Target Frame Select Button
            'SourceFrameSelect', [2 1 5] ...  % Tab Container > "Main" tab > "Param Group" > Source Frame Select Button
            );

        SysObjBlockName = 'SourceBlock';
    end

    methods
        function maskInitialize(obj, block)
        %maskInitialize Initialize mask for Get Transform block

            blkH = get_param(block, 'handle');
            maskDisplayText = sprintf('color(''black'');');
            maskDisplayText = sprintf('%s\nport_label(''output'', 1, ''IsAvail'');',maskDisplayText);
            maskDisplayText = sprintf('%s\nport_label(''output'', 2, ''Value'');',maskDisplayText);
            set_param(blkH, 'MaskDisplay', maskDisplayText);
            % Add block icon
            ros.internal.setBlockIcon(blkH, 'rosicons.robotlib_gettransform');
            updateSubsystem(obj,block);
            % Update Bus name for system object block
            sysobj_block = [block '/' obj.SysObjBlockName];
            const_block = [block '/Constant'];
            rosMessageType = 'geometry_msgs/TransformStamped';
            [busDataType, slBusName] = ros.slros.internal.bus.Util.rosMsgTypeToDataTypeStr(rosMessageType, bdroot(block));
            if ~ros.slros.internal.block.CommonMask.isLibraryBlock(block)
                ros.slroscpp.internal.bus.Util.createBusIfNeeded(rosMessageType,bdroot(block));
            end
            set_param(sysobj_block, 'SLBusName', slBusName);
            set_param(const_block,'OutDataTypeStr', busDataType);
        end

        function updateSubsystem(obj, block)
        %updateSubsystem update parameters in system object inside this block
            
            sysobj_block = [block '/' obj.SysObjBlockName];
            modelName = bdroot(block);
            set_param(sysobj_block,'ModelName', modelName);

            % note: we use the block id of the parent, not the sys_obj
            % block
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'TF_');
            set_param(sysobj_block, 'BlockId', blockId);
            
            % There is no need to manually propagate to subsystem since all
            % other parameters has been promoted in block mask.
        end
        
        function frameSourceSelect(obj, block)
            maskValues = get_param(block, 'MaskValues');
            maskVisibilities = get_param(block,'MaskVisibilities');
            maskEnables = get_param(block,'MaskEnables');

            mask = Simulink.Mask.get(block);
            dlg = mask.getDialogControls;

            ts = obj.MaskDlgIndex.TargetFrameSelect;
            ss = obj.MaskDlgIndex.SourceFrameSelect;

            if strcmpi(maskValues{obj.MaskParamIndex.FrameSourceDropdown},obj.TopicSourceSpecifyOwn)
                % Custom frame
                % Enable editing of frames
                maskEnables{obj.MaskParamIndex.TargetFrameEdit} = 'on';
                maskEnables{obj.MaskParamIndex.SourceFrameEdit} = 'on';
                % Hide Frame selection 
                dlg(ts(1)).DialogControls(ts(2)).DialogControls(ts(3)).Visible = 'off';
                dlg(ss(1)).DialogControls(ss(2)).DialogControls(ss(3)).Visible = 'off';
            else
                % Select from ROS network
                maskEnables{obj.MaskParamIndex.TargetFrameEdit} = 'off';
                maskEnables{obj.MaskParamIndex.SourceFrameEdit} = 'off';
                % Show Frame selection
                dlg(ts(1)).DialogControls(ts(2)).DialogControls(ts(3)).Visible = 'on';
                dlg(ss(1)).DialogControls(ss(2)).DialogControls(ss(3)).Visible = 'on';
            end

            set_param(block,'MaskEnables',maskEnables);
            set_param(block,'MaskVisibilities',maskVisibilities);
        end

        function frameSelect(~,block,frameType,getDlgFcn)
            try
                frameDlg = feval(getDlgFcn);
                modelName = bdroot(block);
                frameDlg.openDialog(@dialogCloseCallback, modelName);
            catch ME
                % Send error to Simulink diagnostic viewer rather than a
                % DDG dialog
                % NOTE: This does NOT stop execution.
                reportAsError(MSLDiagnostic(ME));
            end

            function dialogCloseCallback(isAcceptedSelection, selectedFrame)
                if isAcceptedSelection
                    set_param(block, frameType, selectedFrame);
                end
            end
        end

        function modelCloseFcn(~, block)
        %modelCloseFcn Called when the model is closed

        % Avoid clearing buses when library is closed
        % (prevents clearing when library unloaded on simulation)
            ros.slros.internal.bus.clearBusesOnModelClose(block);
        end
    end

    methods(Static)
        function dispatch(methodName, varargin)
            obj = ros.slros.internal.block.GetTransformBlockMask();
            obj.(methodName)(varargin{:});
        end
    end
end