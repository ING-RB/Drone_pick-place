classdef (Abstract) DocLocationHandler
    properties
        LandingPage (1,1) string
    end

    properties (Dependent, Access=?matlab.internal.doc.services.DocLocation)
        DocRootDomain
    end

    methods
        function domain = get.DocRootDomain(obj)
            domain = obj.getDocRootDomain;
        end

        function url = getDocRootUrl(obj, options)
            arguments
                obj (1,1) matlab.internal.doc.services.DocLocationHandler
                options (1,1) struct = struct
            end
            url = obj.getDocRootDomain(options);
            url.Path = obj.getDocRootPath(options);
        end        
    end

    methods (Access=protected)
        function obj = DocLocationHandler(landingPage)
            obj.LandingPage = landingPage;
            persistent serverEnabled
            if isempty(serverEnabled)
                mwDocSearchConfig = struct("domain", matlab.internal.doc.getDocCenterDomain, ...
                    "release", matlab.internal.doc.getDocCenterRelease);
                matlab.internal.doc.search.sendSearchMessage("docconfig", "Params", mwDocSearchConfig);
                serverEnabled = true;
            end
        end
    end

    methods (Access=?matlab.internal.doc.services.DocLocation)
        function [relUri, release] = isUnderDocRoot(obj,url)
            release = string.empty;
            if ~isa(url,'matlab.net.URI')
                url = matlab.net.URI(url);
            end
            
            if obj.isUnderDocRootDomain(url)
                if ~isempty(url.Path)
                    url.Path(url.Path == "") = [];
                end
                [relUri, release] = obj.getPathUnderDocRoot(url);
            else
                relUri = matlab.net.URI.empty;
            end
        end
        
        function match = isUnderDocRootDomain(obj, url)
            if ~isa(url, "matlab.net.URI")
                url = matlab.net.URI(url);
            end
            
            docDomain = obj.getDocRootDomain;
            % Clean up online doc URLs so that we do not get mismatches
            % due to subdomains
            docHost = regexprep(lower(docDomain.Host),"^www[^.]*\.mathworks\.com$","mathworks.com");
            urlHost = regexprep(lower(url.Host),"^www[^.]*\.mathworks\.com$","mathworks.com");
            match = docHost == urlHost;
        end
    end

    methods(Abstract)
        [baseUrl, relUrl] = getSearchUrl(obj, release, searchTerm)
        domain = getDocRootDomain(obj, options)
    end

    methods(Abstract,Access=protected)
        path = getDocRootPath(obj, options)
        [relPath, archive, release] = getPathUnderDocRoot(obj,path)
    end
end

%   Copyright 2019-2024 The MathWorks, Inc.
