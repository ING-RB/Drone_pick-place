classdef HelpCommandDocPageHandler < matlab.internal.doc.ui.DocPageHandler
    properties
        Topic (1,1) string = "";
    end    

    methods
        function obj = set.Topic(obj, topic)
            obj.Topic = topic;
        end
        
        function topic = get.Topic(obj)
            topic = obj.Topic;
        end
    end    

    methods (Access = protected)
        function success = openBrowserForDocPage(obj, ~)
            help(obj.Topic, '-displayBanner');
            success = true;
        end
    end      
end

% Copyright 2021-2024 The MathWorks, Inc.
