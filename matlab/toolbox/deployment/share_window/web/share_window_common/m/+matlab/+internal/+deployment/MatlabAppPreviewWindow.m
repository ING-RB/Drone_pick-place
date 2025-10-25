classdef MatlabAppPreviewWindow < matlab.internal.deployment.AppShareWindow
    methods
        function obj = MatlabAppPreviewWindow(appFullFileName)
            obj@matlab.internal.deployment.AppShareWindow(appFullFileName, 'matlabapp', 'prev');
        end
    end
    methods (Access = protected)
        function [title, minSize, position] = getWindowSettings(obj)
            title = string(message("compiler_ui_common:messages:previewDialogTitleMatlabApp"));
            position = obj.getCenteredPosition(675, 990, 0.8);
            minSize = [500 280];
        end
    end
end