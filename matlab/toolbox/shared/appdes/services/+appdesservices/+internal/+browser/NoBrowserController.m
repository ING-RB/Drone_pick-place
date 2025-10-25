classdef NoBrowserController < appdesservices.internal.browser.AbstractBrowserController
    %NoBrowserController Class to start no browser
    %   
    
    %    Copyright 2015 The MathWorks, Inc.
    
    properties(Access = private)
        % Cleanup handle
        BrowserCleanup
    end
    
    properties(SetAccess = 'private')
       IsBrowserValid = true;
    end
    
    methods (Access = public)
        function obj = NoBrowserController(varargin)
            
            obj = obj@appdesservices.internal.browser.AbstractBrowserController(varargin{:});
        end
    end
    
    methods(Access = protected)
        
        function startBrowser(obj, browserOptions)
            
            % Return a no-op on cleanup object
            
            obj.BrowserCleanup = onCleanup(@() [ ]);         
            
            % Diagnostic for sandbox workflows
            fprintf('\nBrowser URL:\n\n\t%s\n', browserOptions.URL);
        end
                
        function closeBrowser(obj)
            delete(obj.BrowserCleanup);
        end
    end
    
end

