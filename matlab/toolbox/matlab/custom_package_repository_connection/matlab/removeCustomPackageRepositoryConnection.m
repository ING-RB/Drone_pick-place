function removeCustomPackageRepositoryConnection (customRepoUserPath)
    %

    %   Copyright 2024 The MathWorks, Inc.
    mpmRemoveRepository(customRepoUserPath);
    matlab.internal.addons.Sidepanel.removeCustomRepositoryFromPanel(customRepoUserPath);
end
