function isLicensed = isSimscapeMultibodyLicensed
%This function is for internal use only. It may be removed in the future.

%isSimscapeMultibodyLicensed Returns true if Simscape Multibody is installed and licensed
%   This function checks if the Simscape Multibody Toolbox
%   is installed and its license can be used. If this is the
%   case, additional functionality in Robotics System Toolbox
%   becomes available.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    persistent isInstalled

    if coder.target('MATLAB') && ~isdeployed
        % Use "ver" to determine if "mech" is installed.
        % Use a persistent variable here, since "ver" can be slow.
        % It is highly unlikely that the installation status will change during a
        % MATLAB session, so a persistent is appropriate.

        if isempty(isInstalled)
            isInstalled = ~isempty(ver('mech'));
        end

        isLicensed = license('test', 'SimMechanics') && isInstalled;
    else
        % ver and license are not supported in codegen or when deploying with
        % MATLAB Compiler. Assume Simscape Multibody is installed.

        isLicensed = true;
    end

end
