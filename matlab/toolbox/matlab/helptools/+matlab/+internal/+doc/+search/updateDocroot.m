function success = updateDocroot(docrootFolder)
    arguments
        docrootFolder (1,1) string = docroot
    end
    params = struct('docroot',docrootFolder);
    success = matlab.internal.doc.search.sendSearchMessage("docconfig", "Params", params);
end