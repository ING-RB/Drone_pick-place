function validatedFileName = getValidatedInputAppFileName(inputFileNameOrPath)
    %GETVALIDATEDINPUTFILENAME Check and return the validated input .mlapp file
    % name.
    %   If the file name is not valid or not exist, error will be thrown
    %   otherwise, return a validated full file name

    %    Copyright 2017-2024 The MathWorks, Inc.

    % the filename can either be a character vector or string, but if a
    % string it must be scalar (i.e. dimension of 1)
    if ~ischar(inputFileNameOrPath) && ~(isstring(inputFileNameOrPath) && isscalar(inputFileNameOrPath))
        error(message('MATLAB:appdesigner:appdesigner:InvalidInput'));
    end
    inputFileNameOrPath = char(inputFileNameOrPath);

    [~, file, ext] = fileparts(inputFileNameOrPath);

    if iskeyword(file)
        error(message('MATLAB:appdesigner:appdesigner:FileNameFailsIsKeyword'));
    end

    if ~isvarname(file)
        error(message('MATLAB:appdesigner:appdesigner:FileNameFailsIsVarName', file, namelengthmax));
    end

    % Append the default file extension if necessary.
    candidateFullFile = ...
        appdesigner.internal.serialization.util.appendFileExtensionIfNeeded(inputFileNameOrPath);

    appdesigner.internal.serialization.util.validateAppFileExtension(candidateFullFile);

    % The candidate name is valid.
    validatedFileName = candidateFullFile;    

    if ~exist(validatedFileName, 'file')
        error(message('MATLAB:appdesigner:appdesigner:InvalidFileName', validatedFileName));
    end

    % Get the full file path of the app.
    [success, fileInfo, ~] = fileattrib(validatedFileName);

    fmt = appdesigner.internal.serialization.util.getFileFormatByExtension(inputFileNameOrPath);
    
    if success
        switch fmt
            case appdesigner.internal.serialization.FileFormat.Text
                validatedFileName = appdesigner.internal.application.normalizeFullFileName(fileInfo.Name, '.m');
            otherwise
                validatedFileName = appdesigner.internal.application.normalizeFullFileName(fileInfo.Name, '.mlapp');
        end
        
    else
        % which only works for the file in the MATLAB search path, and also
        % return the normalized file path
        validatedFileName = which(validatedFileName);
    end
end
