classdef MacBrowserHandler < matlab.internal.web.SystemBrowserHandler
    methods(Access = protected)
        function [stat, msg] = handleOpenSystemBrowser(~, url)
            stat = 0;
            msg = '';

            % Since we're opening the system browser using the NextStep open command,
            % we must specify a syntactically valid URL, even if the user didn't
            % specify one.  We choose The MathWorks web site as the default.
            if isempty(url)
                url = 'http://www.mathworks.com';
            else
                % If no protocol specified, or an absolute/UNC pathname is not given,
                % include explicit 'http:'.  MAC command needs the http://.
                if ~contains(url,':') && ~startsWith(url,'\\') && ~startsWith(url,'/')
                    url = strcat('http://', url);
                end
            end
            unix("open """ + url + """");            
        end
    end
end

