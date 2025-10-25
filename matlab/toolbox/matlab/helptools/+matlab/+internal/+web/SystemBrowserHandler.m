classdef (Abstract, HandleCompatible) SystemBrowserHandler
    methods(Sealed, Access = {?matlab.internal.web.AbstractSystemBrowserLauncher, ?matlab.internal.web.SystemBrowserHandler})
        function [stat, msg] = openSystemBrowser(obj, url)
            [stat, msg] = handleOpenSystemBrowser(obj, url);
        end
    end

    methods(Abstract, Access = protected)
        [stat, msg] = handleOpenSystemBrowser(obj, url)
    end
end
