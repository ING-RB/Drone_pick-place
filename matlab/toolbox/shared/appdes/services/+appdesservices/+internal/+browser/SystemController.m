classdef SystemController < appdesservices.internal.browser.AbstractBrowserController
    % Class to start system browser using the web command
    
    %    Copyright 2023 The MathWorks, Inc.        
    
    properties(SetAccess = 'private')
        IsBrowserValid = false;
    end
    
    methods                
    end
    
    methods (Access = protected)
        
        function startBrowser(obj, browserOptions)
            status = web(browserOptions.URL, '-browser');
            
            % Status codes
            % 0 Found and started system browser.
            % 1 Could not find system browser.
            % 2 Found, but could not start system browser.
            
            obj.IsBrowserValid = (status == 0);                        
        end        
    end
    
    methods (Access = protected)
        function closeBrowser(obj)
            % no op
        end
    end
    
end

