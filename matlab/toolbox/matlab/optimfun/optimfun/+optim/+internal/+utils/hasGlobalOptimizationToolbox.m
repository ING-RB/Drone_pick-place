function tf = hasGlobalOptimizationToolbox()
    % Check if the Global Optimization Toolbox is available

    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    % Check license
    isLicensed = license('test', 'GADS_Toolbox') == 1;

    % Check installation. Only perform ver check once per MATLAB session,
    % as it is expensive if called in a tight loop. It's also unexpected
    % installation status would change within a MATLAB session.
    persistent isInstalled;
    if isempty(isInstalled)
        isInstalled = ~isempty(ver('globaloptim'));
    end

    % Toolbox use requires both license and installation
    tf = isLicensed && isInstalled;
end
