function [tempMATFileLocation, cleanupObj] = extractMATFile(mlappFileName)
    % EXTRACTMATFILE extracts the AppDesigner MLAPP file
    % copy mat file to temp location
    % 
    % tempMATFileLocation - file location for mat file
    % cleanupObj - clean up callback to delete temp file

    % Copyright 2021 - 2022 The MathWorks, Inc.

    % validate to have minimum two output arguments to make sure onCleanup to happen from caller side.
    nargoutchk(2, 2);

    [~, name, ext] = fileparts(mlappFileName);

    % Data from the MLAPP file will be copied to a local
    % .mat file in a temporary directory
    tempMATFileLocation = [tempname, '.mat'];

    % Copy data from file to the temporary location
    try
        appdesigner.internal.serialization.copyAppDataToFile(mlappFileName, tempMATFileLocation);
    catch me
        error(message('MATLAB:appdesigner:appdesigner:LoadFailed', [name, ext]));
    end
    t = tic;
    while (exist(tempMATFileLocation, 'file')~=2 && toc(t) < 10)
    end

    % EXIST returns 2 for files.
    if exist(tempMATFileLocation, 'file')~=2
        error(message('MATLAB:appdesigner:appdesigner:TransferOfDataFailed', mlappFileName));
    end

    function cleanupFile()
        % The temporary file will need to be deleted after usage
        delete(tempMATFileLocation);
    end

    cleanupObj = onCleanup(@()cleanupFile());
end