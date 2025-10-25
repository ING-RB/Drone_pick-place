classdef WebDocHandler < matlab.internal.doc.services.DocLocationHandler
    methods (Access=?matlab.internal.doc.services.DocLocation)
        function obj = WebDocHandler
            obj = obj@matlab.internal.doc.services.DocLocationHandler("index.html"); 
        end
    end
    
    methods (Access=protected)
        function path = getDocRootPath(~, options)
            if ~isempty(options.Release)
                path = ["help", "releases", options.Release];
            else
                path = "help";
            end
        end

        function [result, release] = getPathUnderDocRoot(~,relUri)
            release = string.empty;
            relPath = relUri.Path;
            if isempty(relPath) || relPath(1) ~= "help"
                result = matlab.net.URI.empty;
                return;
            else
                result = matlab.net.URI;
                result.Path = relUri.Path;
                result.Query = relUri.Query;
                result.Fragment = relUri.Fragment;
            end
            
            if length(relPath) >= 3 && relPath(2) == "releases"
                if matlab.internal.doc.url.isValidDocRelease(relPath(3))
                    release = relPath(3);
                    result.Path(1:3) = [];
                    return;
                end
            end
            result.Path(1) = [];
        end
    end

    methods
        function domain = getDocRootDomain(~,~)
            domain = matlab.net.URI(matlab.internal.doc.getDocCenterDomain);
        end        

        function [baseUrl, relUrl] = getSearchUrl(obj, release, searchTerm)
            relUrl = matlab.net.URI;
            if obj.isHelpCenter(release)
                baseUrl = obj.getDocRootDomain;
                relUrl.Path = ["support" "search.html"];
                paramName = "q";
            else
                baseUrl = obj.getDocRootUrl(struct("Release", release));
                relUrl.Path = "search.html";
                paramName = "qdoc";
            end
            
            if nargin > 2
                searchParam = matlab.net.QueryParameter(paramName, searchTerm);
                relUrl.Query = searchParam;
            end
        end        
    end

    methods (Access=private)
        function hc = isHelpCenter(obj, release)
            hc = false;
            % Check for current doc on a mathworks domain
            if isempty(release)
                baseUrl = obj.getDocRootDomain;
                p = (textBoundary("start") | ".") + "mathworks.com";
                hc = contains(baseUrl.Host, p);
            end
        end
    end
end

%   Copyright 2019-2020 The MathWorks, Inc.
