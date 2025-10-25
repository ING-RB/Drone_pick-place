classdef MatlabAppPackageWindow < matlab.internal.deployment.AppShareWindow
    methods
        function obj = MatlabAppPackageWindow(appFullFileName, script)
            obj@matlab.internal.deployment.AppShareWindow(appFullFileName, 'matlabapp', 'pkg', script, '');
        end
    end
    methods (Access = protected)
        function [title, minSize, position] = getWindowSettings(obj)
            title = string(message("compiler_ui_common:messages:progressMessageMatlabApp"));
            position = obj.getCenteredPosition(600, 290, 0.8);
            minSize = [600 280];
        end
    end
end