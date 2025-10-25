function pathStruct = createOutputNames(files, location, nvStruct, origFileSep)
%createOutputNames    Create output filenames

%   Copyright 2023 The MathWorks, Inc.

    import matlab.io.datastore.internal.write.utility.makeOutputName;
    import matlab.io.datastore.internal.write.utility.vectorizedFileparts;
    filesSize = size(files,1);
    folders = strings(filesSize,1);
    names = strings(filesSize,1);
    ext = strings(filesSize,1);
    if filesSize == 1
        files = {files};
    end

    % Make output location a fully-qualified path.
    if isfolder(location)
        dirOutput = dir(location);
        if ~isempty(dirOutput)
            location = string(dirOutput(1).folder);
        end
    end

    % for each file name, convert to its output location name using
    % FolderLayout, FilenamePrefix, FilenameSuffix, and OutputFormat
    for ii = 1 : numel(files)
        if size(nvStruct.OutputFormat,1) > 1
            outFmt = nvStruct.OutputFormat{1};
        else
            outFmt = nvStruct.OutputFormat;
        end
        outputName = makeOutputName(string(files{ii}), location, ...
            nvStruct.Folders, nvStruct.FolderLayout, outFmt, ...
            nvStruct.FilenamePrefix, nvStruct.FilenameSuffix, origFileSep, ...
            nvStruct.WriteFcn);
        [folders(ii), names(ii), ext(ii)] = fileparts(outputName);
    end

    % Get unique names for the output file names
    uniqNames = matlab.lang.makeUniqueStrings(folders + origFileSep + names);
    % Add the extension back 
    uniqNames = uniqNames + ext;
    [folders,names,ext] = vectorizedFileparts(uniqNames);
    % Return a struct containing parts of the path
    pathStruct = struct("Folders", folders, "Filenames", names, "Extensions", ext);
end
