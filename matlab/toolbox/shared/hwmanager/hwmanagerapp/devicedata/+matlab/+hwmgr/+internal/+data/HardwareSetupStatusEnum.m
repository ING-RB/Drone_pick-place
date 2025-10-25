classdef HardwareSetupStatusEnum
    %HARDWARESETUPSTATUSENUM - Enumeration class that defines Hardware Setup status.

    % Copyright 2023 The MathWorks, Inc.

    enumeration
        %ALREADYRAN - Hardware Setup ran to completion successfully.
        AlreadyRan

        %DIDNOTRUN - Hardware Setup did not run yet.
        DidNotRun
    end
end