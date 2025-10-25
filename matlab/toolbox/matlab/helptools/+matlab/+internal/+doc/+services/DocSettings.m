classdef DocSettings < handle
    properties
        ConnectorForExternalBrowser (1,1) logical = false
    end

    properties (Dependent)
        Release (1,1) string
        Domain (1,1) string
    end

    methods (Access=private)
        function obj = DocSettings
        end
    end
    
    methods
        function set.Release(~, release)
            s = settings;
            s.matlab.help.DocRelease.TemporaryValue = release;
        end

        function release = get.Release(~)
            s = settings;
            release = s.matlab.help.DocRelease.ActiveValue;
            if isempty(release) || release == ""
                release = matlabRelease.Release;
            end            
        end

        function set.Domain(~, domain)
            s = settings;
            s.matlab.help.DocCenterDomain.TemporaryValue = domain;
        end

        function domain = get.Domain(~)
            s = settings;
            domain = s.matlab.help.DocCenterDomain.ActiveValue;
            if isempty(domain) || domain == ""
                helpUrl = matlab.net.URI(matlab.internal.UrlManager().HELP);
                helpUrl.Path = [];
                domain = string(helpUrl);
            end
        end
    end

    methods (Static)
        function s = instance
            persistent singleton
            if isempty(singleton)
                singleton = matlab.internal.doc.services.DocSettings;
            end
            s = singleton;
        end

        function setRelease(release)
            s = matlab.internal.doc.services.DocSettings.instance;
            s.Release = release;
        end

        function setDomain(domain)
            s = matlab.internal.doc.services.DocSettings.instance;
            s.Domain = domain;
        end
    end
end
