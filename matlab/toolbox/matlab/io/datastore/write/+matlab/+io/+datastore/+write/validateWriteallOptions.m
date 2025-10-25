function nvStruct = validateWriteallOptions(ds, folders, nvStruct, outFmt)
%validateWriteallOptions    Helper function that validates each name-value
%   pair of the writeall method.
%   Returns a struct with normalized argument values.

%   Copyright 2023-2024 The MathWorks, Inc.

    import matlab.io.datastore.write.*;
    % Validation for Folders, FolderLayout and UseParallel.
    nvStruct.Folders      = validateFolders(folders);  
    nvStruct.FolderLayout = validateFolderLayout(ds, nvStruct.FolderLayout, ...
        nvStruct.Folders);
    nvStruct.UseParallel  = validateUseParallel(nvStruct.UseParallel);

    % Validation for FilenamePrefix and FilenameSuffix.
    nvStruct.FilenamePrefix = validateFilenamePrefix(nvStruct.FilenamePrefix);
    nvStruct.FilenameSuffix = validateFilenameSuffix(nvStruct.FilenameSuffix);

    % Are we using a custom WriteFcn and OutputFormat or not?
    usingCustomWriteFcn = ~any(contains(nvStruct.UsingDefaults, "WriteFcn"));
    usingCustomOutputFormat = ~any(contains(nvStruct.UsingDefaults, "OutputFormat"));

    % Verify that WriteFcn and OutputFormat aren't provided together. Also
    % make sure that either WriteFcn or OutputFormat is provided when using
    % TransformedDatastore.
    checkFileFormatAndWriteFcnRequirements(ds, usingCustomWriteFcn, ...
        usingCustomOutputFormat, nvStruct.OutputFormat);
    
    % Validate the WriteFcn and OutputFormat N-V pairs.
    if usingCustomWriteFcn
        nvStruct.WriteFcn = validateWriteFcn(nvStruct.WriteFcn);
        % Ensure that no underlying writer-specific input arguments are 
        % provided when using WriteFcn.
        if ~isempty(nvStruct.Unmatched)
            error(message("MATLAB:io:datastore:write:write:ExtraParametersWithWriteFcn", ...
                nvStruct.Unmatched{1}));
        end
    else
        validateOutputFormat(nvStruct.OutputFormat, outFmt);
    end
end

function checkFileFormatAndWriteFcnRequirements(~, usingCustomWriteFcn, ...
    usingCustomOutputFormat, outFmt)

    % Custom OutputFormat and WriteFcn cannot be specified together.
    if usingCustomWriteFcn && usingCustomOutputFormat
        error(message("MATLAB:io:datastore:write:write:FileFormatOrWriteFcn"));
    end

    % If the default OutputFormat is missing, this implies that the user must
    % specify a known OutputFormat or provide a custom WriteFcn.
    % This is required to correctly validate the write inputs for
    % TransformedDatastore, CombinedDatastore, and FileDatastore.
    if outFmt == "" && ~usingCustomWriteFcn
        % Error if neither a WriteFcn nor a OutputFormat is not provided.
        msgid = "MATLAB:io:datastore:write:write:RequiresFileFormatOrWriteFcn";
        error(message(msgid));
    end
end
