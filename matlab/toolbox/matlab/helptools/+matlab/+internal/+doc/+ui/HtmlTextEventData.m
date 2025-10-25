classdef (ConstructOnLoad) HtmlTextEventData < event.EventData
    properties
        HtmlText (1,1) string
        Success (1,1) logical
    end

    methods
        function obj = HtmlTextEventData(htmlText, success)
            obj.HtmlText = htmlText;
            obj.Success = success;
        end
    end
end