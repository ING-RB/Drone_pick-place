classdef CurrentTimeBlockMask
%This class is for internal use only. It may be removed in the future.

%CurrentTimeBlockMask - Block mask callbacks for ROS2 Current Time block

%   Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'ros.slros2.internal.block.CurrentTime'
    end

    methods

        function maskInitialize(~, block) 
        %maskInitialize Initialize the block mask
        % * Causes the icon to be redrawn
            blkH = get_param(block, 'handle');
            ros.internal.setBlockIcon(blkH, 'rosicons.ros2lib_currenttime');
            if ~ros.slros.internal.block.CommonMask.isLibraryBlock(block)
                ros.slros2.internal.bus.Util.createBusIfNeeded('builtin_interfaces/Time', bdroot(block));
            end
        end

        function initFcn(~, block)
        %initFcn Called when the model initializes the block
            modelName = bdroot(block);
            % Do not mark the model dirty when mode name is updated, since
            % that information is only transient.
            preserveDirty = Simulink.PreserveDirtyFlag(bdroot(block),'blockDiagram');
            set_param(block, 'ModelName', modelName);
            delete(preserveDirty);
        end

        function outputFormatSelect(~, block)
        %outputTypeSelect Called when output type gets updated
            modelName = bdroot(block);
            isBusSelected = strcmp('bus',get_param(block,'OutputFormat'));
            if ~ros.slros.internal.block.CommonMask.isLibraryBlock(block) && isBusSelected
                ros.slros2.internal.bus.Util.createBusIfNeeded('builtin_interfaces/Time', modelName);
            end
        end

        function modelCloseFcn(~)
        %modelCloseFcn Called when the model is closed

        % Delete all message buses for this particular model
            ros.slros2.internal.bus.Util.clearSLBusesInGlobalScope;
        end
    end

    methods(Static)

        function dispatch(methodName, varargin)
        %dispatch Dispatch to static methods in this class
            obj = ros.slros2.internal.block.CurrentTimeBlockMask;
            obj.(methodName)(varargin{:});
        end

    end
end
