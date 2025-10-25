function files = getFiles(name) 
    allFiles = string(which(name,'-all'));
    mlroot = matlabroot;
    sproot = getSupportPackageRoot;
    notUnderMatlab = removeFilesUnderRoot(allFiles, mlroot);
    if ~isempty(sproot)
        files = removeFilesUnderRoot(notUnderMatlab, sproot);
    else
        files = notUnderMatlab;
    end
end

function files = removeFilesUnderRoot(allFiles, root)
    notUnderRoot = ~startsWith(allFiles,root);
    files = allFiles(notUnderRoot);
end

function sproot = getSupportPackageRoot
    try
        sproot = matlabshared.supportpkg.internal.getSupportPackageRootNoCreate;
    catch
        sproot = '';
    end
end

% Copyright 2021 The MathWorks, Inc.