classdef HelpwinPage < matlab.internal.doc.url.DocPage
    properties (Constant)
        HelpWinPath = ["ui" "help" "helpwin"];
    end

    properties
        Topic (1,1) string;
        HelpCommand (1,1) string;
    end
    
    methods
        function obj = HelpwinPage(topic, helpCommand)
            arguments
                topic (1,1) string = "";
                helpCommand (1,1) string = "helpwin";
            end
            obj.Topic = topic;
            obj.HelpCommand = helpCommand;
            obj.ContentType = "MatlabFileHelp";
            obj.IsValid = true;
            obj.SupportedLocations = "INSTALLED";
            
            obj.DisplayOptions.Size = [800, 500];
            obj.DisplayOptions.Title = getString(message('MATLAB:helpwin:Title', topic));
            obj.Origin = matlab.internal.doc.url.DocPageOrigin("Helpwin", [topic,helpCommand]);
        end
    end
    
    methods (Access = protected)
        function url = buildUrl(obj)
            options = struct('InternalBrowser', true);
            domain = obj.DocLocation.getDocRootDomain(options);
            url = matlab.net.URI(domain);
            
            if getenv('MW_CSH_DEBUG')
                helpwinPage = "index-debug.html";
            else
                helpwinPage = "index.html";
            end
            url.Path = [matlab.internal.doc.url.HelpwinPage.HelpWinPath helpwinPage];
            
            topicParam = matlab.net.QueryParameter("topic", obj.Topic);
            helpCmdParam = matlab.net.QueryParameter("helpCommandOption", obj.HelpCommand);
            url.Query = [topicParam, helpCmdParam];
        end
    end
end

% Copyright 2020-2021 The MathWorks, Inc.