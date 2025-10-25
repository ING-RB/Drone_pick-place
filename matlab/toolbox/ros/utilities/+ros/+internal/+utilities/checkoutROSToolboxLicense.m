function checkoutROSToolboxLicense()
%

%   Copyright 2024 The MathWorks, Inc.

    licenseAvailable = license('checkout','ROS_Toolbox');

    if ~licenseAvailable
        error(message('ros:utilities:util:NoLicenseAvailable'))
    end
end