function helpDir = setDocroot(helpDir)
%

%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        helpDir (1,1) string = "";
    end

    % correct slashes
    helpDir = fullfile(helpDir);
    % remove trailing directory separator
    helpDir = strip(helpDir, 'right', filesep);

    matlab.internal.doc.docroot.setDocroot(helpDir);

    dataDir = matlab.internal.doc.docroot.getDocDataRoot;

    matlab.internal.doc.updateConnectorDocroot(helpDir, dataDir);
    if dataDir ~= ""
        matlab.internal.reference.SetReferenceRoot(dataDir);
        matlab.internal.example.SetExampleRoot(dataDir);
    end    
end
