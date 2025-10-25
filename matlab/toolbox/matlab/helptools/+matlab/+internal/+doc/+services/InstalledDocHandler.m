classdef InstalledDocHandler < matlab.internal.doc.services.DocLocationHandler
    methods (Access=?matlab.internal.doc.services.DocLocation)
        function obj = InstalledDocHandler
            obj = obj@matlab.internal.doc.services.DocLocationHandler("documentation-center.html");
        end
    end
    
    methods
        function domain = getDocRootDomain(obj, options)
            arguments
                obj (1,1) matlab.internal.doc.services.InstalledDocHandler
                options (1,1) struct = struct
            end
            persistent serverEnabled

            internal = isfield(options, "InternalBrowser") && options.InternalBrowser;
            if obj.isUsingConnector || internal
                matlab.internal.doc.services.InstalledDocHandler.enableStaticContentHosting;
                domain = matlab.net.URI(connector.getUrl("/"));
            else
                if isempty(serverEnabled)
                    enableHostingParam = struct("host", "true");
                    matlab.internal.doc.search.sendSearchMessage("docconfig", "Params", enableHostingParam);
                    serverEnabled = true;
                end
                domain = matlab.net.URI;
                domain.Scheme = "http";
                domain.Host = "127.0.0.1";
                domain.Port = matlab.internal.doc.search.getSearchPort;
            end
        end

        function [baseUrl, relUrl] = getSearchUrl(obj, release, searchTerm)
            baseUrl = obj.getDocRootUrl(struct("Release", release)); 
            relUrl = matlab.net.URI;
            relUrl.Path = ["templates" "searchresults.html"];
            if nargin > 2
                searchParam = matlab.net.QueryParameter("qdoc", searchTerm);
                relUrl.Query = searchParam;
            end
        end
    end
    
    methods(Access=protected)
        function path = getDocRootPath(~,~)
            path = ["static", "help"];
        end

        function [result, release] = getPathUnderDocRoot(~,relUri)
            release = string.empty;
            path = relUri.Path;
            if length(path) >= 2 && isequal(path(1:2),["static","help"])
                result = relUri;
                result.Path(1:2) = [];
                % Don't keep the security nonce. We'll regenerate it
                % later if we still need it.
                if ~isempty(result.Query)
                    result.Query([result.Query.Name] == "snc") = [];
                end
            else
                result = matlab.net.URI.empty;
            end
        end
    end

    methods (Static)
        function useConnector = isUsingConnector()
            useConnector = true;
            if matlab.internal.doc.ui.useSystemBrowser
                s = matlab.internal.doc.services.DocSettings.instance;
                useConnector = s.ConnectorForExternalBrowser;
            end
        end

        function enableStaticContentHosting
            persistent hostingEnabled;
            if isempty(hostingEnabled)
                matlab.internal.doc.staticcontent.initializeStaticContent;
                hostingEnabled = true;
            end
        end
    end
end

%   Copyright 2019-2023 The MathWorks, Inc.
