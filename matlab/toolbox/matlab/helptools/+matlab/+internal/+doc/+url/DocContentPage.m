classdef (Abstract) DocContentPage < matlab.internal.doc.url.DocPage
    properties
        Product;
    end

    properties (Dependent = true)
        RelativePath string;
        Query matlab.net.QueryParameter;
        Fragment string;
    end
        
    properties (Hidden, SetAccess=?matlab.internal.doc.url.DocPageParser)
        RelativeUri (1,1) matlab.net.URI;
    end
    
    methods
        % Get and set methods
        % Used to provide flexible property assignment via strings and to
        % maintain consistent state of dependent properties
        function obj = set.Product(obj,value)
            if isempty(value) 
                obj.Product = [];
            elseif isstruct(value) && isfield(value,'HelpLocation')
                obj.Product = value;
            elseif isstring(value) || ischar(value)
                prod = matlab.internal.doc.url.getDocPageProduct(value);
                if isempty(prod)
                    prod = matlab.internal.doc.project.getDocPageCustomToolbox(value);
                end
                obj.Product = prod;
            end
        end
        
        function relPath = get.RelativePath(obj)
            % Always correct landing page URLs.
            if obj.isLandingPage
                if isempty(obj.Product)
                    relPath = obj.DocLocation.getLandingPage;
                else
                    relPath = "index.html";
                end
            else
                relPath = obj.RelativeUri.Path;
            end
        end
        
        function obj = set.RelativePath(obj,value)
            if isempty(value)
                value = matlab.net.URI;
            end
            if ~isa(value,"matlab.net.URI")
                splitPath = matlab.internal.doc.url.DocContentPage.splitPath(value);
                value = matlab.net.URI(join(splitPath,"/"));
            end
            obj.RelativeUri.Path = value.Path;
            obj.RelativeUri.Query = [obj.RelativeUri.Query value.Query];
            if ~isempty(value.Fragment)
                obj.RelativeUri.Fragment = value.Fragment;
            end
        end

        function value = get.Query(obj)
            value = obj.RelativeUri.Query;
        end
        
        function obj = set.Query(obj,value)
            if ~isa(value,"matlab.net.QueryParameter")
                value = matlab.net.QueryParameter(value);
            end
            obj.RelativeUri.Query = [obj.RelativeUri.Query value];
        end
        
        function value = get.Fragment(obj)
            value = obj.RelativeUri.Fragment;
        end
        
        function obj = set.Fragment(obj,value)
            obj.RelativeUri.Fragment = value;
        end
        
        function landing = isLandingPage(obj)
            path = obj.RelativeUri.Path;
            if isempty(path) || (isStringScalar(path) && path == "index.html")
                landing = true;
            elseif isempty(obj.Product)
                landing =  isStringScalar(path) && path == obj.DocLocation.getLandingPage;
            else
                landing = false;
            end
        end

        function url = getDocRootUrl(obj)
            internal = obj.ContentType == "Standalone";
            release = string.empty;
            if obj.UseArchive
                release = obj.Release;
            end
            url = obj.DocLocation.getDocRootUrl("InternalBrowser", internal, "Release", release);
        end
    end
    
    methods (Access = protected)
        function url = buildUrl(obj)
            if ~obj.IsValid
                url = matlab.net.URI;
                return;
            end
            
            url = getDocRootUrl(obj);
            if ~isempty(obj.Product)
                helpLocation = matlab.internal.doc.url.DocContentPage.splitPath(obj.Product.HelpLocation);
                url.Path = [url.Path helpLocation];
            end
            % Use obj.RelativePath here to get any logic in the get method
            url.Path = [url.Path obj.RelativePath];
            url.Query = [url.Query obj.Query];
            url.Fragment = [url.Fragment obj.Fragment];
        end        
    end
    
    methods (Access = private)
        function relativeUri = getRelativeUri(obj)
            if obj.isLandingPage
                relativeUri = matlab.net.URI;
                if isempty(obj.Product)
                    relativeUri.Path = string(obj.DocLocation.getLandingPage);
                else
                    relativeUri.Path = [relativeUri.Path "index.html"];
                end
            else
                relativeUri = obj.RelativeUri;
            end
        end
    end

    methods (Static, Access=protected)
        function pathParts = splitPath(path)
            pathParts = join(path,"/");
            pathParts = split(pathParts,"/"|"\")';
            pathParts(pathParts == "") = [];
            pathParts = reshape(pathParts, [1,numel(pathParts)]);
        end
    end
end

% Copyright 2020-2021 The MathWorks, Inc.