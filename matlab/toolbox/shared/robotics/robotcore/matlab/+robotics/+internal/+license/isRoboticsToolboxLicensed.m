function isLicensed = isRoboticsToolboxLicensed
%This function is for internal use only. It may be removed in the future.

%isRoboticsToolboxLicensed Returns true if Robotics System Toolbox is installed and licensed
%   This function checks if the Robotics System Toolbox
%   is installed and its license can be used.

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    persistent isInstalled

    if coder.target('MATLAB') && ~isdeployed
        % Use "ver" to determine if "robotics" is installed.
        % Use a persistent variable here, since "ver" can be slow.
        % It is highly unlikely that the installation status will change during a
        % MATLAB session, so a persistent is appropriate.

        if isempty(isInstalled)
            isInstalled = ~isempty(ver('robotics'));
        end

        isLicensed = license('test', 'Robotics_System_Toolbox') && isInstalled;
    else
        % ver and license are not supported in codegen or when deploying with
        % MATLAB Compiler. Assume, Robotics System Toolbox is installed.

        isLicensed = true;
    end

end
