function examplesXml = findExamplesXml(component,arg)
%

%   Copyright 2022-2023 The MathWorks, Inc.

found = false;

if matlab.internal.examples.isInstalled
    examplesXml = fullfile(fileparts(docroot), 'examples', component, 'examples.xml');
    if isfile(examplesXml)
        found = true;
    else
        try
            examplesXml = fullfile(matlabshared.supportpkg.getSupportPackageRoot, 'examples', component, 'examples.xml');
        catch e
            if ~strcmp(e.identifier,'supportpkgservices:supportpackageroot:UnableToReadSPRoot')
                % Unexpected error, rethrow it
                rethrow(e)
            end
        end
        found = isfile(examplesXml);
        if ~found
            error(message("MATLAB:examples:InvalidInstalledExample",arg));
        end
    end
else
    examplesDir = fullfile(matlab.internal.examples.getExamplesDir, component);
    if ~isfolder(examplesDir)
        mkdir(examplesDir);
    end
    examplesXml = fullfile(examplesDir, 'examples.xml');
    found = matlab.internal.examples.copyFromWeb(component, '', 'examples.xml', examplesXml, false);
    if ~found
        error(message("MATLAB:examples:InvalidWebExample",arg));
    end
end


