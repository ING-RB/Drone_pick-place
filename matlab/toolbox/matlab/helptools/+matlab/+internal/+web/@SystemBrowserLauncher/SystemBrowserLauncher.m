classdef SystemBrowserLauncher < matlab.internal.web.AbstractSystemBrowserLauncher
    properties (Hidden, Access = private)
        Handler (1,1);
    end
    
    methods        
        function obj = SystemBrowserLauncher()
            handler = [];
            
            if matlab.internal.web.isMatlabOnlineEnv
                handler = matlab.internal.web.MatlabOnlineBrowserHandler;
            elseif ismac
                handler = matlab.internal.web.MacBrowserHandler;
            elseif isunix
                handler = matlab.internal.web.UnixBrowserHandler;
            elseif ispc
                handler = matlab.internal.web.WindowsBrowserHandler;
            end
            
            obj.Handler = handler;
        end
    end    
    
    methods
        function handler = getSystemBrowserHandler(obj)
            handler = obj.Handler;
        end        
    end
end