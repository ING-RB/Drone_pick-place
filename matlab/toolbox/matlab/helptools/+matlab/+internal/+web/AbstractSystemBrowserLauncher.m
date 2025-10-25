classdef (Abstract, HandleCompatible) AbstractSystemBrowserLauncher
    methods (Sealed)
        function [stat, msg] = openSystemBrowser(obj, url)
            handler = obj.getSystemBrowserHandler;
            if ~isempty(handler)                
                [stat, msg] = openSystemBrowser(handler, url);                
            else
                errID = 'SystemBrowserLauncher:UnsupportedEnvironment';
                msg = message('MATLAB:web:UnsupportedEnvironment');
                throw(MException(errID,msg));
            end
        end
    end
    
    methods(Abstract)
        handler = getSystemBrowserHandler(obj)
    end
end