function isLicensed = isOptimToolboxLicensed
%This function is for internal use only. It may be removed in the future.

%isOptimToolboxLicensed Returns true if Optimization Toolbox is installed and licensed
%   This function checks if the Optimization Toolbox
%   is installed and its license can be used. If this is the
%   case, additional functionality in Robotics System Toolbox
%   becomes available.

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen

    persistent isInstalled

    if coder.target('MATLAB') && ~isdeployed
        % Use "ver" to determine if "optim" is installed.
        % Use a persistent variable here, since "ver" can be slow.
        % It is highly unlikely that the installation status will change during a
        % MATLAB session, so a persistent is appropriate.

        if isempty(isInstalled)
            isInstalled = ~isempty(ver('optim'));
        end

        isLicensed = license('test', 'Optimization_Toolbox') && isInstalled;
    else
        % ver and license are not supported in codegen or when deploying with
        % MATLAB Compiler. Assume, Optimization Toolbox is installed.

        isLicensed = true;
    end

end
