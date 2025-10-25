function files = findDocCatalogFiles(catalogFolder, shortname, extension)
    arguments
        catalogFolder (1,1) string
        shortname (1,1) string
        extension (1,1) string = ".json"
    end

    dataRoot = matlab.internal.doc.docroot.getDocDataRoot;
    folder = fullfile(dataRoot, "docCatalog", catalogFolder);
    files = matlab.internal.doc.csh.getLocalizedFileList(folder, shortname, extension);
end

        