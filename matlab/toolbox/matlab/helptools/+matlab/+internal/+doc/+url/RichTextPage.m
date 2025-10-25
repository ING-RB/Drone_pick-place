classdef RichTextPage < matlab.internal.doc.url.DocPage
    properties (Constant)
        RichTextPath = ["ui", "help", "richtextdoc"];
    end

    properties
        Topic (1,1) string;
        FileType (1,1) string;
    end

    methods
        function obj = RichTextPage(topic, fileType)
            arguments
                topic (1,1) string = "";
                fileType (1,1) string = "m";
            end
            obj.Topic = topic;
            obj.ContentType = "Standalone";
            obj.IsValid = true;
            obj.SupportedLocations = "INSTALLED";
            obj.FileType = fileType;

            obj.DisplayOptions.Size = [800, 500];
            [~, fileName] = fileparts(topic);
            obj.DisplayOptions.Title = fileName;
            obj.Origin = matlab.internal.doc.url.DocPageOrigin("help", topic);
        end
    end

    methods (Access = protected)
        function url = buildUrl(obj)
            options = struct('InternalBrowser', true);
            domain = obj.DocLocation.getDocRootDomain(options);
            url = matlab.net.URI(domain);

            richTextPage = "index.html";
            if getenv('MW_CSH_DEBUG')
                richTextPage = "index-debug.html";
            end
            url.Path = [matlab.internal.doc.url.RichTextPage.RichTextPath richTextPage];

            topicParam = matlab.net.QueryParameter("topic", obj.Topic);
            fileTypeParam = matlab.net.QueryParameter("fileType", obj.FileType);
            url.Query = [topicParam, fileTypeParam];
        end
    end
end

% Copyright 2024 The MathWorks, Inc.