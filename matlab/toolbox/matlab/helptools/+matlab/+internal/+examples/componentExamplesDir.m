function componentDir = componentExamplesDir(component)
%

%   Copyright 2020-2023 The MathWorks, Inc.

componentDir = fullfile(fileparts(docroot),'examples',component);
examplesXml = fullfile(componentDir,'examples.xml');

if ~isfile(examplesXml)
    try
        componentDir = fullfile(matlabshared.supportpkg.getSupportPackageRoot, 'examples', component);
    catch
    end
    examplesXml = fullfile(componentDir,'examples.xml');
    if ~isfile(examplesXml)
        error(message("MATLAB:examples:InvalidArgument",component))
    end
end
