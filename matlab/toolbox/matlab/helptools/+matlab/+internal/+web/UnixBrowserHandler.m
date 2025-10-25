classdef UnixBrowserHandler < matlab.internal.web.SystemBrowserHandler
    methods(Access = protected)
        function [stat, msg] = handleOpenSystemBrowser(~, url)            
            stat = 0;
            msg = '';

            % Get the system browser and options from settings.
            s = settings;
            doccmd = s.matlab.web.SystemBrowser.ActiveValue;
            unixOptions = s.matlab.web.SystemBrowserOptions.ActiveValue;

            if isempty(doccmd)
                % The preference has not been set from the preferences dialog, so use the default.
                doccmd = 'firefox';
            end

            % Use 'which' to determine if the user's browser exists, since we
            % can't catch an accurate status when attempting to start the
            % browser since it must be run in the background.
            [status,output] = unix(['which ', doccmd]);
            if status ~= 0
                stat = 1;
                msg = message('MATLAB:web:BrowserNotFound', output);                
            end

            if stat == 0   
                % Need to escape ! on UNIX
                url = regexprep(url, '!','\\$0');

                % For the system browser, always send a file: URL
                location = matlab.internal.web.resolveLocation(url);
                if ~isempty(location)
                    url = string(location);
                end

                % browser not running, then start it up.
                comm = string(doccmd) + " " + unixOptions + " '" + string(url) + "' &";

                % g1269624, we need to temporary clean out the LD_LIBRARY_PATH path, after command execution, we set it back.
                tmp = getenv('LD_LIBRARY_PATH'); 
                setenv('LD_LIBRARY_PATH','') 
                oc = onCleanup(@() setenv('LD_LIBRARY_PATH',tmp));
                [status,output] = unix(comm);
                delete(oc);

                if status
                    stat = 1;
                end

                if stat ~= 0
                    msg = message('MATLAB:web:BrowserNotFound', output);

                end
            end            
        end
    end    
end

