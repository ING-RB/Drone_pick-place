classdef DocLocation < handle
    enumeration
        WEB (matlab.internal.doc.services.WebDocHandler)
        INSTALLED(matlab.internal.doc.services.InstalledDocHandler)
    end
    
    properties (Access=private)
        Handler;
    end
    
    methods
        function obj = DocLocation(handler)
            obj.Handler = handler;
        end
        
        function landingPage = getLandingPage(obj)
           landingPage = obj.Handler.LandingPage; 
        end
        
        function url = getDocRootDomain(obj, options)
            arguments
                obj (1,1) matlab.internal.doc.services.DocLocation
                options (1,1) struct = struct
            end
            url = obj.Handler.getDocRootDomain(options);
        end
        
        function match = isUnderDocRootDomain(obj, url)
            match = obj.Handler.isUnderDocRootDomain(url);
        end
        
        function [relPath, release] = isUnderDocRoot(obj, url)
            [relPath, release] = obj.Handler.isUnderDocRoot(url);
        end
        
        function [baseUrl, relUrl] = getSearchUrl(obj, release, searchTerm)
            arguments
                obj (1,1) matlab.internal.doc.services.DocLocation;
                release string = string.empty;
                searchTerm string = string.empty;
            end
            [baseUrl, relUrl] = obj.Handler.getSearchUrl(release, searchTerm);
        end
    end

    methods (Access=?matlab.internal.doc.url.DocPage)
        function url = getDocRootUrl(obj, options)
            arguments
                obj (1,1) matlab.internal.doc.services.DocLocation
                options.Release string = string.empty
                options.InternalBrowser (1,1) logical = false
            end
            url = obj.Handler.getDocRootUrl(options);
        end
    end

    methods (Static)
        function loc = getActiveLocation
            loc = matlab.internal.doc.services.DocLocation(matlab.internal.doc.getDocLocation);
        end
    end
end

%   Copyright 2019-2023 The MathWorks, Inc.
