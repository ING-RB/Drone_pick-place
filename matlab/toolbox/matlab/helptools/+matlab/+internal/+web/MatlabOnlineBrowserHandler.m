classdef MatlabOnlineBrowserHandler < matlab.internal.web.SystemBrowserHandler
    methods(Access = protected)
        function [stat, msg] = handleOpenSystemBrowser(~, url)
            stat = 0;
            msg = '';
            displayUrl = matlab.internal.web.MatlabOnlineBrowserHandler.getDisplayUrl(url);
            import matlab.internal.capability.Capability;
            if (Capability.isSupported(Capability.WebWindow))
                w = matlab.internal.webwindow(displayUrl, 'WindowContainer', 'Tabbed');
                w.show;
            elseif ~matlab.internal.web.isLocalContent(displayUrl)
                message.publish("/web/doc", string(displayUrl));
            else
                error(message('MATLAB:web:UnsupportedEnvironment'));
            end
        end
    end

    methods (Static, Access = private)
        function display_url = getDisplayUrl(url)
            if startsWith(url, 'http://') || startsWith(url, 'https://')
                display_url = char(url);
            else
                fileLocation = matlab.internal.web.FileLocation(url);
                if ~isempty(fileLocation.FilePath) && (fileLocation.FileExists || isfolder(fileparts(fileLocation.FilePath)))
                    filepath = char(fileLocation.FilePath);
                    display_url = connector.getUrl(matlab.ui.internal.URLUtils.getURLToUserFile(filepath));
                else
                    throw(MException('MATLAB:Connector:FolderNotFound', 'Directory does not exist.'));
                end
            end
        end
    end
end

% Copyright 2021-2023 The MathWorks, Inc.
