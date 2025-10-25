function isLicensed = isROSToolboxLicensed
%This function is for internal use only. It may be removed in the future.

%isROSToolboxLicensed Returns true if ROS Toolbox is installed and licensed
%   This function checks if the ROS Toolbox is installed and its license
%   can be used.

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    persistent isInstalled

    if coder.target('MATLAB') && ~isdeployed
        % Use "ver" to determine if "ros" is installed.
        % Use a persistent variable here, since "ver" can be slow.
        % It is highly unlikely that the installation status will change during a
        % MATLAB session, so a persistent is appropriate.

        if isempty(isInstalled)
            isInstalled = ~isempty(ver('ros'));
        end

        isLicensed = license('test', 'ROS_Toolbox') && isInstalled;
    else
        % ver and license are not supported in codegen or when deploying with
        % MATLAB Compiler. Assume ROS Toolbox is installed.

        isLicensed = true;
    end

end
