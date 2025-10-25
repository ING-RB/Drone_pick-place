classdef RunnerInterface < handle
    % RunnerInterface this is used as shared interface between 
    % App Designer API (DesktopRunnder.m) and system test (AppDesignerBaseTestCase)
    % in order to gain friend access frrom system tests

    % Copyright 2021 The MathWorks, Inc.

    properties (Constant)
        CallbackErrorHandler = appdesigner.internal.apprun.CallbackErrorHandler.instance();
    end

    methods (Abstract)
        run(obj)
    end

    methods (Static)
        function addAppPathToMATLABPath(fullFilePath)
            % Add to the MATLAB search path to ensure callback or user
            % authored functions executed correctly. If the path already
            % in the search path, it would move it to the top
            appPath = appdesigner.internal.service.util.PathUtil.getPathToApp(fullFilePath);

            addpath(appPath);
        end
    end
end