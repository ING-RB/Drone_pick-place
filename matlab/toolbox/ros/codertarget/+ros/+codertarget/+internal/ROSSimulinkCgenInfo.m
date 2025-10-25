classdef ROSSimulinkCgenInfo < handle
%This class is for internal use only. It may be removed in the future.

%   ROSSimulinkCgenInfo is a utility class that encapsulates information
%   about ROS use in a Simulink model used for code generation.

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = private)
        CustomMsgPkgName = {}
        BuildMissingMsgs = false
    end

    methods (Access = private)
        % Private constructor to prevent explicit object construction
        function obj = ROSSimulinkCgenInfo
        end
    end

    %% Singleton class access method
    methods (Static)
        function obj = getInstance
            persistent instance__
            if isempty(instance__)
                instance__ = ros.codertarget.internal.ROSSimulinkCgenInfo();
            end
            obj = instance__;
        end
    end

    methods
        function reset(obj)
            obj.CustomMsgPkgName = {};
        end

        function addToCustomMsgPkgName(obj, pkgNames)
            for pkgName = pkgNames
                obj.CustomMsgPkgName{end+1} = pkgName{1};
            end
        end

        function pkgNames = getCustomMsgPkgName(obj)
            pkgNames = unique(obj.CustomMsgPkgName);
        end

        function setBuildMissingMsgs(obj, allowBuildMsgs)
            obj.BuildMissingMsgs = allowBuildMsgs;
        end

        function buildMissingMsgs = getBuildMissingMsgs(obj)
            buildMissingMsgs = obj.BuildMissingMsgs;
        end
    end
end