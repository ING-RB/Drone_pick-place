classdef ROSControlUtilBase
    %This class is for internal use only. It may be removed in the future.

    %  ROSControlUtilBase Base class for ROS/ROS 2 controller
    %  utilities.

    %    Copyright 2024 The MathWorks, Inc.

    methods (Static)
        function rosVersion = getROSVersion(modelName)
            %getROSVersion get ROS version from model ConfigSet
            open_system(modelName);
            activeConfigObj = getActiveConfigSet(modelName);
            hwROSVersion = get_param(activeConfigObj,'HardwareBoard');
            % App is only visible if current model is configured as a
            % ROS or ROS 2 model
            if strcmp(hwROSVersion,getString(message('ros:slros:cgen:ui_hwboard')))
                % ROS hardware board
                rosVersion = 'ROS';
            else
                % ROS 2 hardware board
                rosVersion = 'ROS 2';
            end
        end

        function ret = getROSControlSettings(modelName)
            import ros.slros.internal.dlg.ROSControlSpecifier
            w = get_param(modelName,'ModelWorkspace');
            ret.InportTable = getDataFromWorkspace(w,ROSControlSpecifier.InportTableVarName);
            ret.OutportTable = getDataFromWorkspace(w,ROSControlSpecifier.OutportTableVarName);
            ret.ClassName = getDataFromWorkspace(w,ROSControlSpecifier.ClassNameVarName);
            ret.ParamTable = getDataFromWorkspace(w,ROSControlSpecifier.ParamTableVarName);
            function outval = getDataFromWorkspace(wkspc, varName)
                if hasVariable(wkspc,varName)
                    outval = evalin(wkspc,varName);
                else
                    outval = [];
                end
            end
        end

        function ret = getRootIOAccessFormat(cinfo)
            if ~isempty(cinfo.codeInfo.Inports)
                ret = class(cinfo.codeInfo.Inports(1).Implementation);
            else
                ret = class(cinfo.codeInfo.Outports(1).Implementation);
            end
            hasBothRootIO = ~isempty(cinfo.codeInfo.Inports) && ~isempty(cinfo.codeInfo.Outports);
            if (hasBothRootIO)
                inputImplType = class(cinfo.codeInfo.Inports(1).Implementation);
                outputImplType = class(cinfo.codeInfo.Outports(1).Implementation);
                assert(isequal(inputImplType,outputImplType),...
                    'Root-level input and output port data interfaces do not match.')
            end
        end

        function ret = hasROSControlReconfigureParams(modelName)
            % HASROSCONTROLRECONFIGUREPARAMS Returns true if the
            % GenerateROSControl flag of the model is set to true and any
            % of the parameters are selected for use with dynamic
            % reconfigure
            %
            % Example:
            %  import ros.codertarget.internal.ROSControlUtilBase
            %  ROSControlUtilBase.hasROSControlReconfigureParams(modelName)

            ret = ros.codertarget.internal.Util.isROSControlEnabled(modelName);
            % Proceed accessing model workspace if and only if the model is
            % configured with ROS and 'GenerateROSControl' flag is true
            if ret
                s = ros.codertarget.internal.ROSControlUtilBase.getROSControlSettings(modelName);
                ret = isfield(s,'ParamTable') &&...
                    ~isempty(s.ParamTable) &&...
                    any([s.ParamTable{:,4}]);
            end
        end
    end
end