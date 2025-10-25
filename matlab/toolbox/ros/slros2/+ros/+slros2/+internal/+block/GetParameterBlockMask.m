classdef GetParameterBlockMask < ros.slros.internal.block.CommonMask
%This class is for internal use only. It may be removed in the future.

%GetParameterBlockMask Block mask callbacks for ROS 2 GetParameter block
%   Note that we are using a mask-on-mask on top of the GetParameter
%   system object. This has the advantage of easy customization, in
%   addition to the easy manipulation of the number of input and output
%   ports.

%   Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'ros.slros2.internal.block.GetParameter';

        %MaskParamIndex - Struct specifying index of various parameters
        MaskParamIndex = struct( ...
            'ParamNameEdit', 1, ...
            'ParamDataTypeDropdown', 2, ...
            'ParamInitialValueEdit', 3, ...
            'ParamMaxArrayLengthEdit', 4 ...
            );

        %MaskParamIndex - Struct specifying index of various widgets
        MaskDlgIndex = struct( )

        SysObjBlockName = '';
    end

    methods
        function updateSubsystem(~, block)
        %updateSubsystem Update the Block ID and Model Name
            blockId = ros.slros.internal.block.getCppIdentifierForBlock(block, 'ParamGet_');
            modelName = bdroot(block);
            set_param(block, 'ModelName', modelName);
            set_param(block, 'BlockId', blockId);
        end

        function maskInitialize(~, block)
            blkH = get_param(block, 'handle');
            ros.internal.setBlockIcon(blkH, 'rosicons.ros2lib_getparam');
        end
    end
    methods (Access = protected)
        function setParameterType(obj, block)
            %setParameterType Callback when the user selects a parameter data type
            obj.updateSubsystem(block);
        end
    end

    methods(Static)
        function dispatch(methodName, varargin)
        %dispatch Static dispatch method for callbacks

            obj = ros.slros2.internal.block.GetParameterBlockMask();
            obj.(methodName)(varargin{:});
        end
    end
end
