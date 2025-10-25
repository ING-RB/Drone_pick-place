classdef DocSearchPage < matlab.internal.doc.url.DocPage
    properties (SetAccess = private)
        SearchTerm (1,1) string = "";
    end
    
    methods
        function obj = DocSearchPage(searchTerm)
            if ~nargin || isempty(searchTerm)
                obj.SearchTerm = "";
            elseif isa(searchTerm, "matlab.net.QueryParameter")
                obj.SearchTerm = matlab.internal.doc.url.DocSearchPage.getSearchQuery(searchTerm);
            elseif ischar(searchTerm) || isstring(searchTerm)
                obj.SearchTerm = string(searchTerm);
            end
            obj.IsValid = true;
            obj.DocLocation = matlab.internal.doc.services.DocLocation.getActiveLocation;
            obj.UseArchive = matlab.internal.doc.url.useArchiveDoc;
            obj.Origin = matlab.internal.doc.url.DocPageOrigin("Search", obj.SearchTerm);
        end
    end
    
    methods (Access = protected)
        function url = buildUrl(obj)
            release = string.empty;
            if obj.UseArchive
                release = obj.Release;
            end
            if obj.SearchTerm == ""
                docPage = matlab.internal.doc.url.MwDocPage;
                docPage.UseArchive = obj.UseArchive;
                url = docPage.getUrl;
            else
                [url, relUrl] = obj.DocLocation.getSearchUrl(release, obj.SearchTerm);
                url.Path = [url.Path relUrl.Path];
                url.Query = [url.Query relUrl.Query];
                url.Fragment = relUrl.Fragment;
            end
        end
    end

    methods (Static, Access=private)
        function query = getSearchQuery(queryParams)
            query = matlab.net.QueryParameter.empty;
            paramNames = string([queryParams.Name]);
            queryIdx = find(matches(paramNames, "q"|"qdoc"));
            if ~isempty(queryIdx)
                query = queryParams(queryIdx).Value;
            end
        end
    end

end

% Copyright 2020-2023 The MathWorks, Inc.
