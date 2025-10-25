classdef LaunchModeEnum
    %LAUNCHMODE - Enumeration class that defines Hardware Setup Launch mode.

    % Copyright 2023 The MathWorks, Inc.

    enumeration
        %REQUIRED - Hardware Setup must run to completion before using the hardware
        Required

        %OPTIONAL - Hardware Setup is not required to run before using the hardware
        Optional
    end
end