classdef UrlDocPageParser < matlab.internal.doc.url.DocPageParser
    methods
        function obj = UrlDocPageParser(url)
            obj.Input = url;
            [isHelpPage, url] = matlab.internal.doc.url.UrlDocPageParser.checkForHelpBrowserUrl(url);
            obj.IsDocPage = isHelpPage;

            if isempty(url)
                % If we get here and the URL is still empty, use the landing page.
                return;
            end

            locs = enumeration("matlab.internal.doc.services.DocLocation");
            for i = 1:length(locs)
                loc = locs(i);
                [relUri, release] = loc.isUnderDocRoot(url);
                if ~isempty(relUri)
                    obj.RelUri = relUri;
                    obj.Location = loc;
                    obj.Release = release;
                    obj.IsDocPage = true;
                    return;
                end
            end
            
            relUri = matlab.internal.doc.url.UrlDocPageParser.checkOutsideDocroot(url);
            if ~isempty(relUri)
                obj.RelUri = relUri;
                obj.Location = "WEB";
                obj.IsDocPage = false;
            end
        end
    end

    methods (Static, Access=private)
        function relUri = checkOutsideDocroot(url)
            if matlab.internal.doc.services.DocLocation.WEB.isUnderDocRootDomain(url)
                relUri = matlab.net.URI;
                relUri.Path = url.Path;
                relUri.Query = url.Query;
                relUri.Fragment = url.Fragment;
            else
                relUri = matlab.net.URI.empty;
            end
        end

        function [isHelpPage, url] = checkForHelpBrowserUrl(url)
            isHelpPage = false;
            if matches(url.Host, "localhost"|"127.0.0.1")
                pathPattern = optionalPattern(asManyOfPattern("/")) + "ui/help/helpbrowser";
                if startsWith(url.EncodedPath, pathPattern)
                    isHelpPage = true;
                    query = url.Query;
                    locParam = query([query.Name] == "loadurl");
                    if ~isempty(locParam)
                        realUrl = matlab.net.internal.urldecode(locParam.Value);
                        url = matlab.net.URI(realUrl);
                    else
                        url = matlab.net.URI.empty;
                    end
                end
            end
        end        
    end
end
