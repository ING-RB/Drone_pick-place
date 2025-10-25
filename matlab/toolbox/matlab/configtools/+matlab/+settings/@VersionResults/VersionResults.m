classdef VersionResults
    % VersionResults stores the results of upgrading
    % the personal settings of a toolbox to a
    % specific version.

    %   Copyright 2019 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = immutable)
        % Toolbox version 
        VersionLabel(1,1) string
        % Results of the upgrade process 
        VersionChanges matlab.settings.OperationResult
    end
end
