function spkgs = loadSupportPackages
    spkgs = struct.empty;

    sourceFile = fullfile(matlab.internal.doc.docroot.getDocDataRoot, "support_packages.json");
    if ~isfile(sourceFile)
        % No support package information is available.
        return;
    end

    spkgData = jsondecode(fileread(sourceFile));
    if isfield(spkgData, "support_packages")
        spkgs = spkgData.support_packages;
    end
end
% Copyright 2024 The MathWorks, Inc.