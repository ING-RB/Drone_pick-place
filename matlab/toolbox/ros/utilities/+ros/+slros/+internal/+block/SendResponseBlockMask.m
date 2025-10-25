classdef SendResponseBlockMask < ros.slros.internal.block.CommonServiceMask
%This class is for internal use only. It may be removed in the future.

%SendResponseBlockMask - Block mask for Send Response block

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        %% Abstract properties inherited from CommonMask base class
        MaskParamIndex = struct( ...
            'ServiceNameEdit', 1, ...
            'ServiceTypeEdit', 2 ...
            );

        MaskDlgIndex = struct.empty();

        SysObjBlockName = 'SvcSenderObj';
    end

    methods (Static)
        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros.internal.block.SendResponseBlockMask;
            obj.(methodName)(varargin{:});
        end
    end
end