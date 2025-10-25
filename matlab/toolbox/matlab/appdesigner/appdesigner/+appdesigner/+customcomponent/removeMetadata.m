function removeMetadata(customComponentFile)
%REMOVEMETADATA Remove custom UI component metadata for App Designer
%   REMOVEMETADATA(customComponentFile) removes the App Designer metadata
%   for the custom UI component specified by customComponentFile. This
%   removes the component from the App Designer Component Library.
%
%   See also appdesigner.customcomponent.configureMetadata

%   Copyright 2020 The MathWorks, Inc.
import appdesigner.internal.usercomponent.metadata.Constants

narginchk(1, 1);

try
    fullFileName = appdesigner.internal.usercomponent.metadata.getValidatedCustomComponentFile(customComponentFile);
catch exception
    throw(exception);
end

% Create and store Model from the provided userComponentFilePath
model = appdesigner.internal.usercomponent.metadata.Model(fullFileName);
if ~model.getModelValidity()
    error(message([Constants.MessageCatalogPrefix 'InvalidModelErrorMsg']));
end

model.deRegisterComponent();
end