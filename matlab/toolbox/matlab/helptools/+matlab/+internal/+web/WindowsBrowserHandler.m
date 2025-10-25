classdef WindowsBrowserHandler < matlab.internal.web.SystemBrowserHandler
    methods(Access = protected)
        function [stat, msg] = handleOpenSystemBrowser(~, url)
            msg = message.empty;

            if startsWith(url, 'mailto:')
                % Use the user's default mail client.
                [stat,output] = dos(strcat('cmd.exe /c start "" "', url, '"'));
            else
                url = strrep(url, '"', '\"');
                % If we're on the filesystem and there's an anchor at the end of
                % the URL, we need to strip it off; otherwise the file won't be
                % displayed in the browser.
                % This is a known limitation of the FileProtocolHandler.
                [uri, filepath] = matlab.internal.web.resolveLocation(url);
                if ~isempty(filepath)
                    [stat,output] = matlab.internal.web.WindowsBrowserHandler.openWithWinOpen(filepath);
                else
                    if ~isempty(uri)
                        if uri.Scheme == "file"
                            uri.Fragment = string.empty;
                        end
                        url = string(uri);
                    end
                    [stat,output] = matlab.internal.web.WindowsBrowserHandler.openWithNativeWindowsCmd(url);
                end
            end

            if stat ~= 0
                msg = message('MATLAB:web:BrowserNotFound', output);
            end             
        end
    end

    methods (Static, Access = private)
        function [stat,output] = openWithWinOpen(filepath)
            if ~isempty(which("winopen"))
                stat = 0;
                output = char.empty;
                winopen(filepath);
            else
                [stat,output] = matlab.internal.web.WindowsBrowserHandler.openWithNativeWindowsCmd(filepath);
            end
        end
        
        function [stat,output] = openWithNativeWindowsCmd(url)
            [stat,output] = dos("cmd.exe /c rundll32 url.dll,FileProtocolHandler """ + url + """");
        end
    end
end

% Copyright 2021-2023 The MathWorks, Inc.