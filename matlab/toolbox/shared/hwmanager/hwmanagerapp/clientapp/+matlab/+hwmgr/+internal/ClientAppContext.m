classdef ClientAppContext < matlab.hwmgr.internal.FrameworkContext
  % CLIENTAPPCONTEXT - FrameworkContext class specialization representing
  % the client app context of a running framework.

  % Copyright 2021 The Mathworks, Inc.
  
    properties (SetAccess = immutable)
        AppletClass
        PluginClass
    end
    
    methods
        function obj = ClientAppContext(appletClass, pluginClass)
            obj@matlab.hwmgr.internal.FrameworkContext(true,false);
            obj.AppletClass = appletClass;
            obj.PluginClass = pluginClass;
        end
        
        function bool = eq(obj, otherContext)
            if ~isa(otherContext, "matlab.hwmgr.internal.ClientAppContext")
                bool = false;
            else
                bool = strcmp(obj.AppletClass, otherContext.AppletClass) ...
                    && strcmp(obj.PluginClass, otherContext.PluginClass);
            end            
        end
    end
end