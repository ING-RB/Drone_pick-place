classdef (Abstract) DocPageParser
    properties (Dependent)
        DocPage (1,1) matlab.internal.doc.url.DocPage
    end

    properties (GetAccess=private, SetAccess=protected)
        Input
        RelUri matlab.net.URI = matlab.net.URI
        Location (1,1) matlab.internal.doc.services.DocLocation = matlab.internal.doc.services.DocLocation.getActiveLocation
        Release string = string.empty
        IsDocPage (1,1) logical = false
        AlternateDocRoot matlab.internal.web.FileLocation = matlab.internal.web.FileLocation.empty
    end

    methods
        function docPage = get.DocPage(obj)
            docPage = findDocPage(obj);
            if docPage.IsValid
                docPage.DocLocation = obj.Location;
                docPage.Release = obj.Release;
                docPage.UseArchive = ~isempty(obj.Release);
                docPage.Origin = matlab.internal.doc.url.DocPageOrigin("ParsedUrl", obj.Input);
            end
        end
    end

    methods (Static)
        function [isDoc, docPage] = isDocPage(docUrl)
            parser = matlab.internal.doc.url.DocPageParser.create(docUrl);
            isDoc = ~isempty(parser) && parser.IsDocPage;
            if nargout > 1
                docPage = parser.DocPage;
            end
        end
    end

    methods (Access=private)
        function docPage = findDocPage(obj)
            [prod, relUri] = findInProduct(obj);
            if ~isempty(prod)
                docPage = matlab.internal.doc.url.MwDocPage;
                docPage.Product = prod;
                docPage.RelativeUri = relUri;
                return;
            end

            [prod, relUri] = findInCustomToolbox(obj);
            if ~isempty(prod)
                docPage = matlab.internal.doc.url.CustomDocPage;
                docPage.Product = prod;
                docPage.RelativeUri = relUri;
                return;
            end

            if isSearchPage(obj)
                query = obj.RelUri.Query;
                docPage = matlab.internal.doc.url.DocSearchPage(query);
                return;
            end

            if obj.IsDocPage
                % This must be a global page.
                docPage = matlab.internal.doc.url.MwDocPage;
                docPage.RelativeUri = obj.RelUri;
            else
                % Return an invalid DocPage instance.
                docPage = matlab.internal.doc.url.DocPage;
            end
        end

        function [prod, relUri] = findInProduct(obj)
            prod = struct.empty;
            relUri = obj.RelUri;
            for i = 1:min(length(obj.RelUri.Path),2)
                prodPath = join(obj.RelUri.Path(1:i),"/");
                prod = matlab.internal.doc.url.getDocPageProduct(prodPath);
                if ~isempty(prod)
                    relUri.Path = obj.RelUri.Path(i+1:end);
                    return;
                end
            end
        end

        function [prod, relUri] = findInCustomToolbox(obj)
            prod = struct.empty;
            relUri = matlab.net.URI.empty;

            if isempty(obj.RelUri.Path)
                return;
            end

            if obj.RelUri.Path(1) == "3ptoolbox"
                if length(obj.RelUri.Path) >= 4
                    prodPath = join(obj.RelUri.Path(1:3),"/");
                    prod = matlab.internal.doc.project.getDocPageCustomToolbox(prodPath);
                    if ~isempty(prod)
                        relUri = matlab.net.URI(obj.RelUri);
                        relUri.Path = relUri.Path(4:end);
                        return;
                    end
                end
            elseif ~isempty(obj.AlternateDocRoot)
                alternateDocRoot = obj.AlternateDocRoot.FilePath;
                prod = matlab.internal.doc.project.getDocPageCustomToolbox(alternateDocRoot);
                if ~isempty(prod)
                    relUri = obj.RelUri;
                end
            end
        end

        function searchPage = isSearchPage(obj)
            [~,relSearchUrl] = obj.Location.getSearchUrl(obj.Release);
            cleanPath = obj.RelUri.Path;
            if ~isempty(cleanPath)
                cleanPath(cleanPath == "") = [];
            end
            searchPage = isequal(relSearchUrl.Path, cleanPath);
        end
    end

    methods (Static, Access=private)
        function parser = create(docUrl)
            if isempty(docUrl)
                parser = [];
            elseif matlab.internal.doc.url.DocPageParser.isFile(docUrl)
                parser = matlab.internal.doc.url.FilePathDocPageParser(docUrl);
            else
                if ~isa(docUrl, "matlab.net.URI")
                    docUrl = matlab.net.URI(docUrl);
                end
                parser = matlab.internal.doc.url.UrlDocPageParser(docUrl);
            end
        end

        function f = isFile(docUrl)
            if isa(docUrl, "matlab.net.URI")
                f = docUrl.Scheme == "file";
            else
                f = ~startsWith(docUrl, "http");
            end
        end
    end

end