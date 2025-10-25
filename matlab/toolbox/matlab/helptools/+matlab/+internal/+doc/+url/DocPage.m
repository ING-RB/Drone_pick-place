classdef DocPage < matlab.mixin.Heterogeneous
    properties
        ContentType (1,1) matlab.internal.doc.url.ContentType = "DocCenter";
        IsValid (1,1) logical = false;
        UseArchive (1,1) logical = false;
        FixedDocLocation (1,1) logical = false;
        DisplayOptions (1,1) struct = struct;
        Origin matlab.internal.doc.url.DocPageOrigin = matlab.internal.doc.url.DocPageOrigin;
    end
    
    properties (Dependent)
        Release string;
        DocLocation matlab.internal.doc.services.DocLocation;
    end

    properties (Access = protected)
        SupportedLocations matlab.internal.doc.services.DocLocation = ["WEB","INSTALLED"];
        LocationIndex (1,1) {mustBeInteger} = 1;
    end

    properties (Access = private)
        FixedRelease string = string.empty;
    end

    methods
        function url = getUrl(obj)
            url = obj.buildUrl;
            if ~isempty(url.Query)
                url.Query([url.Query.Name] == "snc") = [];
            end
        end

        function obj = set.DocLocation(obj, location)
            arguments
                obj (1,1) matlab.internal.doc.url.DocPage
                location (1,1) matlab.internal.doc.services.DocLocation
            end
            idx = find(obj.SupportedLocations == location, 1);
            if ~isempty(idx)
                obj.LocationIndex = idx(1);
            end
        end

        function location = get.DocLocation(obj)
            if (obj.LocationIndex > length(obj.SupportedLocations))
                locationIndex = 1;
            else
                locationIndex = obj.LocationIndex;
            end
            location = obj.SupportedLocations(locationIndex);
        end

        function obj = toActiveDocLocation(obj)
            obj = obj.toDocLocation(matlab.internal.doc.services.DocLocation.getActiveLocation, ...
                  matlab.internal.doc.url.useArchiveDoc);
        end

        function obj = toDocLocation(obj, docLocation, useArchive)
            arguments
                obj (1,1) matlab.internal.doc.url.DocPage;
                docLocation (1,1) matlab.internal.doc.services.DocLocation;
                useArchive (1,1) logical = false;
            end

            if ~obj.FixedDocLocation
                obj.DocLocation = docLocation;
                obj.UseArchive = useArchive;
            end
        end

        function release = get.Release(obj)
            if isempty(obj.FixedRelease)
                release = string(matlab.internal.doc.getDocCenterRelease);
            else
                release = obj.FixedRelease;
            end
        end

        function obj = set.Release(obj, release)
            arguments
                obj (1,1) matlab.internal.doc.url.DocPage
                release string
            end

            if ~isempty(release) && matlab.internal.doc.url.isValidDocRelease(release)
                obj.FixedRelease = release;
            else
                obj.FixedRelease = string.empty;
            end
        end

        function useArchive = get.UseArchive(obj) 
            useArchive = obj.UseArchive && obj.DocLocation == "WEB";
        end

        function pastRelease = isPastReleasePage(obj)
            pastRelease = obj.DocLocation == "WEB" && ~isempty(obj.FixedRelease) && ...
                          obj.FixedRelease ~= matlab.internal.doc.getDocCenterRelease;
        end
    end
    
    methods (Access = protected)
        function url = buildUrl(~)
            url = matlab.net.URI;
        end

        function url = buildNavigationUrl(obj)
            url = obj.buildUrl;
        end
    end

    methods (Sealed)
        function url = getNavigationUrl(obj)
            url = obj.buildNavigationUrl;
            if matlab.internal.doc.ui.useSystemBrowser ...
                && (obj.DocLocation == "INSTALLED" || obj.UseArchive) ...
                && ~isempty(matlab.internal.doc.project.getCustomToolboxes)
                searchQuery = matlab.net.QueryParameter('searchPort', matlab.internal.doc.search.getSearchPort);
                url.Query = [url.Query searchQuery];
            end
        end

        function str = string(obj)
            str = string(obj.getUrl);
        end
        
        function c = char(obj)
            c = char(obj.getUrl);
        end
    end
end

% Copyright 2020-2024 The MathWorks, Inc.
