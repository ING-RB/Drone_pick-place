function [localPythonPath, activatePath, venvDir] = createOrGetLocalPython(forceRecreateVenv)
%This function is for internal use only. It may be removed in the future.

%createOrGetLocalPython Creates a Python virtual environment for ROS1. 
%
% [localPythonPath, activatePath, venvDir] =
% ros.internal.createOrGetLocalPython() returns the Python executable,
% Python activation path and Python virtual environment folder. The Python
% virtual environment is automatically created if it does not exist. You
% must set the Python version using ROS Toolbox preferences prior to
% executing this function.
%
% ros.internal.createOrGetLocalPython(true) Forces re-creation of the
% Python virtual environment. Use this form when you change the minor
% version of Python or when your Python virtual environment is corrupted.
% You must set the Python version using ROS Toolbox preferences prior to
% executing this function.
%
% This function automatically assigns Python virtual environment folder. In
% order to manually assign a root folder for Python virtual environment,
% set MY_PYTHON_VENV environment variable to a folder. Ensure that this
% folder does not contain any spaces. 
%
% Note: The Python environment created by this function is by ROS Toolbox
% for launching ROS core, generating custom messages and deploying a
% Simulink model as a ROS node. The Python virtual environment persists
% between MATLAB sessions.
% 
% Examples:
% 
% % Get current Python virtual environment parameters
% [localPythonPath, activatePath, pyenvDir] = ros.internal.createOrGetLocalPython
%
% % Set Python location and Re-create Python virtual environment
% preferences('ROS Toolbox')
% ros.internal.createOrGetLocalPython(true)
% 
% % Create Python virtual environment under a given root folder
% setenv('MY_PYTHON_VENV','<Path with no spaces>')
% [~, ~, pyenvDir] = ros.internal.createOrGetLocalPython(true)
%
% See also pyenv, setenv, rosinit.

%   Copyright 2019-2022 The MathWorks, Inc.

    if nargin < 1
        forceRecreateVenv = false;
    end
     
    % Get the root directory where Python venv can be created
    rosEnv = ros.internal.ROSEnvironment;
    checkAndCreateVenv(rosEnv,'ros1',forceRecreateVenv);
    [localPythonPath,activatePath,venvDir] = getVenvInformation(rosEnv,'ros1');
end
