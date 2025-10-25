function pageUrl = getHelpTopicUrl(mapFile, topicId)
    % getHelpTopicUrl - Utility function to get the URL of a help topic.

    % Copyright 2019-2024 The MathWorks, Inc.  
    pageUrl = '';
    topicMap = matlab.internal.doc.csh.DocPageTopicMap.fromTopicPath(mapFile);
    if ~isempty(topicMap) && exists(topicMap)
        docPage = topicMap.mapTopic(topicId);
        if docPage.IsValid

            if docPage.DocLocation == "WEB"
                helpPanelUrl = matlab.net.URI(connector.getUrl("ui/help/helpbrowser/index.html"));
                docUrl = docPage.getNavigationUrl;
                docviewerParam = matlab.net.QueryParameter("docviewer", "helpbrowser");
                docUrl.Query = docviewerParam;
                loadUrlParam = matlab.net.QueryParameter("loadurl", string(docUrl));
                helpPanelUrl.Query = [helpPanelUrl.Query, loadUrlParam];
                pageUrl = string(helpPanelUrl);
            else
                % Workaround until g3488099, where we do not display doc in
                % uihtml
                docPage.ContentType = "Standalone";
                pageUrl = string(docPage.getNavigationUrl);
            end
            
        end
    end
end