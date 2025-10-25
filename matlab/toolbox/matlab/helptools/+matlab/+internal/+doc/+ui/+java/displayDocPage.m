function displayDocPage(path, query, fragment)
    arguments
        path (1,1) string
        query (1,1) string = ""
        fragment (1,1) string = ""
    end

    uri = matlab.net.URI(path);
    if query ~= "" 
        uri.Query = matlab.net.QueryParameter(query);
    end
    if fragment ~= ""
        uri.Fragment = fragment;
    end
    
    % Use the appropriate viewer, based on the DocPage content type.   
    docPage = matlab.internal.doc.url.parseDocPage(uri);
    launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
    launcher.openDocPage();
end

% Copyright 2021 The MathWorks, Inc.