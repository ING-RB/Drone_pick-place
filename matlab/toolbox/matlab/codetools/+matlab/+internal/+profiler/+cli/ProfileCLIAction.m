classdef ProfileCLIAction
    % ProfileCLIAction Enumeration with the actions supported by profile.
    %   Not all actions are user-visible.

    %   Copyright 2022 The MathWorks, Inc.

    enumeration
        On
        Off
        Resume
        Clear
        Reset
        Status
        Info
        Viewer
        Report
        None
    end
end