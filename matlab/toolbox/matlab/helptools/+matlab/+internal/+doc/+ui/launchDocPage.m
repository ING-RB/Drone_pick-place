function launchDocPage(relativePath,options)
    arguments
        relativePath (1,1) string = ""
        options.Location (1,1) string = "DocCenter"
    end

    docPage = matlab.internal.doc.url.MwDocPage;
    docPage.RelativePath = relativePath;
    docPage.UseArchive = ~(options.Location == "HelpCenter" && matlab.internal.doc.services.DocLocation.getActiveLocation == "WEB");
    docPage.FixedDocLocation = (options.Location == "HelpCenter");
    launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
    launcher.openDocPage();
end

%   Copyright 2023 The MathWorks, Inc.
