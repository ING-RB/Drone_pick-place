classdef ChromeController < appdesservices.internal.browser.AbstractBrowserController
    %CHROMECONTROLLER Class to start Chrome browser
    %
    
    %    Copyright 2015 The MathWorks, Inc.
    
    properties(Access = private)
        % Chrome process handle
        ChromeProcess
    end    
    
   properties(SetAccess = 'private')
        IsBrowserValid;
   end
    
    methods
        function obj = ChromeController(varargin)            
            obj = obj@appdesservices.internal.browser.AbstractBrowserController(varargin{:});
        end        
        
        function tf = get.IsBrowserValid(obj)
            % Determines if the window is valid
            
            % By default, assume no
            tf = false;
            
            % If we have a Chrome Process, see if its still running
            if ~isempty(obj.ChromeProcess)
                tf = obj.ChromeProcess.isAlive();
            end
        end
    end
    
    methods (Access = protected)
        
        function startBrowser(obj, browserOptions)
            % Launches Chrome
            if ispc
                % get path
                absoluteChromePath = appdesservices.internal.browser.ChromeController.getChromePath();

                % Check that path exists
                assert(~isempty(absoluteChromePath), 'Chrome install could not be found'); 

                commandToExecute = sprintf('%s --new-window %s', absoluteChromePath, browserOptions.URL);

            else
                % MacOS uses the 'open' command and requires any
                % application with spaces ("Google Chrome") in a string
                % array
                commandToExecute = ["open" "-na" "Google Chrome" "--args" "--new-window" browserOptions.URL];
            end
            
            % Diagnostic for sandbox workflows
            fprintf('\nLaunching Chrome to: %s\n', commandToExecute);
            
            % Launch in a separate process
            obj.ChromeProcess = java.lang.Runtime.getRuntime().exec(commandToExecute);
        end
        
    end
    
    methods (Access = protected)
        function closeBrowser(obj)
            obj.ChromeProcess.destroy();
            obj.ChromeProcess = [];
        end
    end
    methods (Static)
        function absoluteChromePath = getChromePath()
            % Locate chrome on disk.  It can be in several locations.
            %
            % Assemble a list of different locations and go through them to
            % find out which ones exist on disk
            chromeFilePaths = {
                % Windows locations
                sprintf('C:\\Users\\%s\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe', getenv('username')), ...
                'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe', ...
                'C:\Program Files\Google\Chrome\Application\chrome.exe'
                };

                 % Determine which location exists
                chromeFilePathIndex = find(cellfun(@exist, chromeFilePaths));
                 % Check that at least one was found
                if(isempty(chromeFilePathIndex))
                    absoluteChromePath = []
                else
                    % Creates the command to launch Chrome
                    %
                    % Ex: "chrome.exe --new-window https://www.mathworks.com"
                    absoluteChromePath = chromeFilePaths{chromeFilePathIndex};

                end
        end
    end
end

