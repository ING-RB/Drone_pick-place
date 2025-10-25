function showDocInstallationHelp
    docPage = matlab.internal.doc.url.MwDocPage;
    docPage.RelativePath = "install/ug/install-documentation.html";
    docPage.DocLocation = "WEB";
    docPage.UseArchive = true;
    web(string(docPage), '-browser');
end