classdef (ConstructOnLoad) DocPageEventData < event.EventData
    properties
        DocPage matlab.internal.doc.url.DocPage
        Success (1,1) logical
    end

    methods
        function obj = DocPageEventData(docPage, success)
            obj.DocPage = docPage;
            obj.Success = success;
        end
    end
end