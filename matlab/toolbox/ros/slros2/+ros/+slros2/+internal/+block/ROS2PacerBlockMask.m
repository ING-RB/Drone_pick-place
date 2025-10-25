classdef ROS2PacerBlockMask
%This class is for internal use only. It may be removed in the future.

%ROS2PacerBlockMask - Block mask callbacks for ROS 2 Pacer block.

%   Copyright 2024 The MathWorks, Inc.

    properties(Constant)
        % System object block name
        SysObjBlockName = 'ROS 2 Pacer';
        
        % Default reset behavior of the block
        DefaultResetBehavior = 'Reset Entire Scene';
    end

    methods

        function changeSampleTime(obj, block)
            % Change sample time as set by the user
            
            % Getting sample time as set by the user
            sampleTime = get_param(block,'SampleTime');

            subsytemBlock = [block,'/',obj.SysObjBlockName];

            prevSampleTime = get_param(subsytemBlock,'SampleTime');

            try
                % Setting sample time as set by the user
                set_param(subsytemBlock,'SampleTime',sampleTime);
            catch ex
                % Setting sample time as previous values
                set_param(block,'SampleTime',prevSampleTime);
                throw(ex);
            end
        end

        function changeResetBehavior(obj,block)
            % Change Reset behavior as set by the user
            % For Reset world, ResetBehavior is set 0, for Reset Time,
            % ResetBehavior is set to 1

            % Getting reset behavior as set by the user
            resetBehavior = get_param(block,'ResetBehavior');

            subsytemBlock = [block,'/',obj.SysObjBlockName];

            % Setting reset behavior as set by the user
            if strcmp(obj.DefaultResetBehavior, resetBehavior)
                set_param(subsytemBlock,'ResetBehavior','0');
            else
                set_param(subsytemBlock,'ResetBehavior','1');
            end
        end

        function openCosimSetup(~, block)
            % Open the Cosim setup Dialog box
            ros.slros.internal.dlg.CosimSetup.retrieveDialog(block);
        end

    end

    methods(Static)

        function ret = getMaskType()
            ret = 'ROS 2 Pacer';
        end

        function dispatch(methodName, varargin)
        %dispatch Dispatch to Static methods in this class
            obj = ros.slros2.internal.block.ROS2PacerBlockMask;
            obj.(methodName)(varargin{:});
        end

    end
end