function ret = isDeploymentTypeEnabled(hObj, type)
%This function is for internal use only. It may be removed in the future.

% isDeploymentTypeEnabled return whether query type is enabled.

%   Copyright 2024 The MathWorks, Inc.

    cset = hObj.getConfigSet;
    if codertarget.data.isValidParameter(cset, 'ROS.DeploymentType')
        deployType = codertarget.data.getParameterValue(cset, 'ROS.DeploymentType');
        ret = contains(deployType, type);
    else
        ret = false;
    end
end