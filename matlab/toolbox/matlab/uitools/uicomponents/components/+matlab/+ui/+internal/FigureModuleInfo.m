classdef FigureModuleInfo < matlab.ui.container.internal.appcontainer.ModuleInfo
    % Copyright 2024 The MathWorks, Inc.
    
    methods
        function moduleInfo = FigureModuleInfo(varargin)
            moduleInfo = moduleInfo@matlab.ui.container.internal.appcontainer.ModuleInfo(varargin{:});
            
            moduleInfo.Name = "gbtfigure_uicontainer"; % Module name
            moduleInfo.Path = "/toolbox/matlab/uitools/figureuicontainerjs/js"; % Module path defined for mw-module-laoder
            moduleInfo.Exports = ["AppContainerFigureFactory"]; % Exports a module provides
        end
    end
end
