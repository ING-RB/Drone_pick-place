function ret = loadDeploymentType(hObj)
%This function is for internal use only. It may be removed in the future.

% loadDeploymentType set the value of 'Deployment Type' at configset.

%   Copyright 2024 The MathWorks, Inc.

    cset = hObj.getConfigSet;

    if codertarget.data.isValidParameter(cset,'ROS.DeploymentType')
        % DeploymentType widget has been created, inhert latest value
        ret = codertarget.data.getParameterValue(cset,'ROS.DeploymentType');

        % Update "Control" and "Component" widget if exist
        if codertarget.data.isValidParameter(cset, 'ROS.GenerateROSComponent')
            enableComponent = contains(ret, 'Component');
            codertarget.data.setParameterValue(cset, 'ROS.GenerateROSComponent', enableComponent);
        end
        if codertarget.data.isValidParameter(cset, 'ROS.GenerateROSControl')
            enableControl = contains(ret, 'Control');
            ctrlAlreadyEnabled = codertarget.data.getParameterValue(cset, 'ROS.GenerateROSControl');
            if ~ctrlAlreadyEnabled && enableControl
                codertarget.data.setParameterValue(cset, 'ROS.GenerateROSControl', enableControl);
            end
        end
        return
    end

    % DeploymentType widget not exist, new model or model saved from older
    % Simulink version, check "Control" and "Component" widget.
    isComponentPkg = false;
    isControlPkg = false;
    if codertarget.data.isValidParameter(cset, 'ROS.GenerateROSComponent')
        isComponentPkg = codertarget.data.getParameterValue(cset, 'ROS.GenerateROSComponent');
    end
    if codertarget.data.isValidParameter(cset, 'ROS.GenerateROSControl')
        isControlPkg = codertarget.data.getParameterValue(cset, 'ROS.GenerateROSControl');
    end

    if isComponentPkg
        % Componetn Node
        ret = message('ros:slros2:codegen:ui_deploymenttype_componentnode').getString;
    elseif isControlPkg
        % ROS Control Plugin
        ret = message('ros:slros2:codegen:ui_deploymenttype_controlplugin').getString;
    else
        % Standard Node
        ret = message('ros:slros2:codegen:ui_deploymenttype_standardnode').getString;
    end
end