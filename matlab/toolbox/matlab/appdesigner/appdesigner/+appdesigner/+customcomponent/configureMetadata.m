function configureMetadata(customComponentFile)
%CONFIGUREMETADATA Configure custom UI component metadata for App Designer
%   CONFIGUREMETADATA(customComponentFile) launches a dialog to configure
%   the metadata to display the component in the App Designer Component
%   Library. After specifying the metadata, a resources folder with an App
%   Designer metadata file is created in the same directory as
%   customComponentFile. When the folder containing customComponentFile
%   and the resources folder containing the metadata file is on the MATLAB
%   path, the component will appear in the App Designer Component Library.
%
%   See also appdesigner.customcomponent.removeMetadata

%   Copyright 2020 The MathWorks, Inc.

narginchk(1, 1);

try
    fullFileName = appdesigner.internal.usercomponent.metadata.getValidatedCustomComponentFile(customComponentFile);
catch exception
    throw(exception);
end

appdesigner.internal.usercomponent.metadata.ConfigureMetadata(fullFileName);

end