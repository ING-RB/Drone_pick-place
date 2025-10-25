classdef (Abstract) ROS2CancelActionGoalBase < ros.slros.internal.block.ROSCancelActionGoalBase
%This class is for internal use only. It may be removed in the future.

%#codegen

%   Copyright 2023 The MathWorks, Inc.
    properties(Constant, Hidden)
        ROSVersion = 'ROS2';
    
        ROS2NodeConst = ros.slros2.internal.cgen.Constants.NodeInterface;
    end

    % public setter/getter methods
    methods
        function obj = ROS2CancelActionGoalBase(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end
    end
end
