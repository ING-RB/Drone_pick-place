classdef DocPageNotifier < handle
    events
        DocPageLaunched
    end

    methods (Access = ?matlab.internal.doc.ui.DocPageLauncher)
        function docPageLaunched(obj, docPage, success)
            data = matlab.internal.doc.ui.DocPageEventData(docPage, success);
            notify(obj, "DocPageLaunched", data);
        end

        function htmlTextLaunched(obj, htmlText, success)
            data = matlab.internal.doc.ui.HtmlTextEventData(htmlText, success);
            notify(obj, "DocPageLaunched", data);
        end
    end
end