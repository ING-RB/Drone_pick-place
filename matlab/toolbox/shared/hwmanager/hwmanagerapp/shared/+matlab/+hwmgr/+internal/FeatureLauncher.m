classdef FeatureLauncher < handle
    % FeatureLauncher is responsible for launching features that are
    % supported by Hardware Manager.

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = private, GetAccess = ?matlab.unittest.TestCase)
        Launchable
    end

    methods
        function obj = FeatureLauncher(launchable)
            obj.Launchable = launchable;
        end

        function launch(obj)
            % Attempts to launch the feature, catching and handling any
            % errors is the caller responsibility.
            obj.Launchable.launch();
        end
    end
end