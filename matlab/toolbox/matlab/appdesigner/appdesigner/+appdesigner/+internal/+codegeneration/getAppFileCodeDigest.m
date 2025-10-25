function [hash, status, statusMessage] = getAppFileCodeDigest(filePath)
    % reads app code from a mlapp file specified by filePath which is the 
    % full file path to a mlapp file and converts into a hash

    % Copyright 2017 The MathWorks, Inc.

    status = 'success';
    hash = '';
    statusMessage = '';
    
    try
        if ~exist(filePath, 'file')
            status = 'file_not_found';
            return;
        end
        
        code = appdesigner.internal.codegeneration.getAppFileCode(filePath);

        hash = appdesigner.internal.codegeneration.createFileHash(code);
    catch ex
        status = 'error';
        statusMessage = ex.message;
    end
end