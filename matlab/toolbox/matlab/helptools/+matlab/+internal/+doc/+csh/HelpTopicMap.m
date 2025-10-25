classdef HelpTopicMap < matlab.internal.doc.csh.DocPageTopicMap

    methods
        function obj = HelpTopicMap(shortname, group)
            arguments
                shortname (1,1) string;
                group (1,1) string = "";
            end
            obj@matlab.internal.doc.csh.DocPageTopicMap(shortname, group);
        end
        
        function helpPath = mapTopic(obj, topicId)
            docPages = mapTopic@matlab.internal.doc.csh.DocPageTopicMap(obj, topicId);
            helpPath = strings(size(docPages));
            for i = 1:length(docPages)
                helpPath(i) = docPages(i).getUrl;
            end
        end
    end
    
    methods (Static)
        function obj = fromTopicPath(topicPath)
            [shortname,group] = matlab.internal.doc.csh.DocPageTopicMap.parseTopicPath(topicPath);
            obj = matlab.internal.doc.csh.HelpTopicMap(shortname,group);
        end
    end
end

% Copyright 2020 The MathWorks, Inc.
