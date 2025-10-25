classdef HwmgrAppContext < matlab.hwmgr.internal.FrameworkContext
    
    properties (SetAccess = immutable)
        PluginClass
    end
    
    methods
        function obj = HwmgrAppContext(pluginsToLoad)
            obj@matlab.hwmgr.internal.FrameworkContext(false, true);
            obj.PluginClass = pluginsToLoad;
        end
        
        function bool = eq(~, otherContext)
            bool = isa(otherContext, "matlab.hwmgr.internal.HwmgrAppContext");
        end
        
    end
end