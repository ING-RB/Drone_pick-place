function outputFilename = makeOutputName(inputFilename, outputLocation, ...
    folders, folderLayout, outputFormat, fnPrefix, fnSuffix, outputFileSep, writeFcn)
%makeOutputName    Generates the suggested output name (string) based on
%   the FolderLayout choice, output location, and the input file name.

%   Copyright 2023-2024 The MathWorks, Inc.

    if folderLayout == "duplicate"
        % List the subfolders found between each DatasetRoots value and the 
        % input filename.
        [inputFolder, filename, origExt] = fileparts(inputFilename);
        tf = matlab.io.internal.vfs.validators.isIRI(convertStringsToChars(inputFolder));
        if ispc && ~tf
            inputFolder = inputFolder + "\";
        else
            inputFolder = inputFolder + "/";
        end
        subfolders = extractAfter(repmat(inputFolder, size(folders)), folders);

        % Pick the largest parent subfolder. This should preserve the
        % maximum folder structure if there are nested subfolders that match.
        subfolderLengths = strlength(subfolders);
        [~, maxIndex] = max(subfolderLengths);
        largestSubfolder = subfolders(maxIndex);
        if filename == "" && largestSubfolder == "" || ...
                isequal(folders(maxIndex), inputFolder)
            % folder was supplied as input, or the input folder matches one
            % of the Folders exactly
            if ~ispc || tf
                indices = strfind(inputFolder, "/");
            else
                indices1 = strfind(inputFolder, "/");
                indices2 = strfind(inputFolder, "\");
                indices = [indices1, indices2];
            end
            largestSubfolder = extractBetween(inputFolder, indices(end-1)+1, ...
                indices(end)-1);
        elseif largestSubfolder ~= ""
            if ~ispc || tf
                indices = strfind(folders{maxIndex}, "/");
            else
                % file separator could be either / or \ on Windows
                indices1 = strfind(folders{maxIndex}, "/");
                indices2 = strfind(folders{maxIndex}, "\");
                indices = [indices1, indices2];
            end
            if isscalar(indices)
                commonPart = "";
            else
                commonPart = extractAfter(folders{maxIndex},indices(end-1));
            end
            largestSubfolder = commonPart + largestSubfolder;
        end
        % Convert a missing subfolder to zero-character 1x1 string to avoid 
        % errors when concatenating later.
        if ismissing(largestSubfolder)
            largestSubfolder = "";
        end

        % When writing from Windows location to remote paths, update the file
        % separators
        if ispc && outputFileSep == "/"
            largestSubfolder = strrep(largestSubfolder, "\", "/");
        end

        % Don't add extension when generating folder names
        if endsWith(outputLocation, outputFileSep)
            outputFilename = outputLocation + largestSubfolder + ...
                outputFileSep + filename;
        else
            outputFilename = outputLocation + outputFileSep + largestSubfolder + ...
                outputFileSep + filename;
        end
        % Use OutputFormat or extension from original file
        if outputFormat ~= ""
            outputFilename = outputFilename + "." + outputFormat;
        elseif isa(writeFcn, "function_handle")
            % append the extension from the original file names
            outputFilename = outputFilename + origExt;
        end
    else
        if matlab.io.internal.common.validators.isGoogleSheet(inputFilename)
            filename = matlab.io.internal.common.validators.extractGoogleSheetIDFromURL(inputFilename);
        else
            [~, filename, ext] = fileparts(inputFilename);
        end

        % Use OutputFormat if its not missing.
        if outputFormat ~= ""
            ext = "." + outputFormat;
        end

        outputFilename = outputLocation + outputFileSep + filename + ext;
    end

    if fnSuffix ~= "" || fnPrefix ~= ""
        [path, outputFilename, ext] = fileparts(outputFilename);
        outputFilename = fnPrefix + outputFilename + fnSuffix;
        if strlength(outputFilename + ext) > 255
            % applying the strict filename length limit imposed by Windows
            error(message("MATLAB:io:datastore:write:write:FilenameExceedsLength"));
        end
        outputFilename = path + outputFileSep + outputFilename + ext;
    end
end
