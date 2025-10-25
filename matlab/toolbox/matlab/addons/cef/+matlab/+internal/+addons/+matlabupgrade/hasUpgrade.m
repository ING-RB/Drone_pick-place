function [upgradeExists, latestRelease] = hasUpgrade(curRelease)
    % Function to check if there is a MATLAB upgrade available for given curRelease

    % Copyright 2021-2023 The MathWorks, Inc.  
    mlUpgradeInstance = com.mathworks.matlab_upgrade.MatlabUpgrade;
    matlabRelease = java.lang.String(curRelease);
    upgradeExists = mlUpgradeInstance.hasUpgrade(matlabRelease);
    latestRelease = matlab.internal.matlabupgrade.getLatestRelease;
end
