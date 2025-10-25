function success = openDocumentation(id)
    success = false;
    spkg = matlab.internal.doc.supportpkg.getSupportPackage(id);
    if ~isempty(spkg)
        landingPage = spkg.landing_page;
        path = landingPage.path;
        if landingPage.type ~= "absolute"
            path = fullfile(docroot, path);
        end
        status = web(path);
        success = status == 0;
    end
end
% Copyright 2024 The MathWorks, Inc.
