function reconstructAfterSettingFiles(pds, files)
%reconstructAfterSettingFiles   Rebuild the ParquetDatastore after the Files
%   property has been set.
%
%   There is a complicated question of whether a new ParquetImportOptions
%   should be detected (effectively losing the user's previous choices
%   of SelectedVariableNames, OutputType, etc) or if it should be re-used
%   from the old ParquetImportOptions (potentially causing an error on the
%   first read if the new file doesn't have the correct VariableNames).
%
%   Since its very unintuitive to users when ParquetDatastore completely
%   clears their VariableNames and OutputType settings, this code will try
%   to re-use the old ParquetImportOptions if we can verify that:
%
%     - all Selected ParquetFileVariableNames are present in the new first
%       file.
%     - all Selected VariableTypes match exactly.
%
%   If these two conditions are not met, then a new ParquetImportOptions is
%   detected and the user's old choice of SelectedVariableNames,
%   OutputType, etc is cleared.

%   Copyright 2022-2023 The MathWorks, Inc.

    import matlab.io.datastore.internal.ParquetDatastore.makeDatastoreFromReadSize

    % Generate a new FileSet.
    fs = matlab.io.datastore.FileSet(files);
    fs.updateFoldersProperty(); % Clear the Folders property after set.Files.

    opts = redetectParquetImportOptions(pds, fs);
    pds.UnderlyingDatastore = makeDatastoreFromReadSize(fs, opts, pds.ReadSize, pds.BlockSize, pds.PartitionMethod);
end

function opts = redetectParquetImportOptions(pds, fs)
    import matlab.io.datastore.internal.ParquetDatastore.introspectFile
    newOpts = introspectFile(fs);
    oldOpts = pds.ImportOptions;

    % Don't warn in these cases since its not likely that an external
    % user is setting Files to/from empty datastore states.
    if ~fs.hasNextFile()
        % There's no new files, so keep this as the original opts.
        opts = oldOpts;
        return;
    elseif isempty(pds.VariableNames)
        % This could happen during Hadoop initialization. Override with the new options.
        opts = newOpts;
        return;
    end

    % Check that all required VariableNames are present in the new first
    % file.
    selectedParquetFileVariableNames = oldOpts.ParquetFileVariableNames(oldOpts.TabularBuilder.SelectedVariableIndices);
    [isfound, indices] = matlab.io.internal.common.builder.TableBuilder.ismember(selectedParquetFileVariableNames, newOpts.ParquetFileVariableNames);

    % Verify that all required SelectedVariableNames are found in the new
    % first file.
    reuseOldOpts = all(isfound, "all");

    if reuseOldOpts
        % Avoid comparing types that are missing.
        missingTypes = ismissing(oldOpts.TabularBuilder.SelectedVariableTypes);
        oldSelectedVariableTypes = oldOpts.TabularBuilder.SelectedVariableTypes(~missingTypes);

        % Extract the new variable types at these indices.
        newSelectedVariableTypes = newOpts.VariableTypes(indices);
        newSelectedVariableTypes = newSelectedVariableTypes(~missingTypes);

        % Only re-use the ParquetImportOptions if all selected VariableTypes
        % match.
        isTypeMatch = newSelectedVariableTypes == oldSelectedVariableTypes;
        reuseOldOpts = all(isTypeMatch, "all");

        if ~reuseOldOpts
            % Show a warning and use the new options.
            msgid = "MATLAB:io:datastore:parquet:validation:ParameterResetDueToVariableTypeChange";
            changedVariableNames = selectedParquetFileVariableNames(~isTypeMatch);
            expectedVariableTypes = oldSelectedVariableTypes(~isTypeMatch);
            expectedVariableTypes = fillmissing(expectedVariableTypes, "constant", "<missing>");
            actualVariableTypes = newSelectedVariableTypes(~isTypeMatch);
            actualVariableTypes = fillmissing(actualVariableTypes, "constant", "<missing>");
            changedVariableNames = changedVariableNames + " (Expected type: " + expectedVariableTypes + ", Actual type in the new first file: " + actualVariableTypes + ")";
            changedVariableNamesString = join("    " + changedVariableNames, newline);
            filename = fs.FileInfo(1).Filename;
            warning(message(msgid, changedVariableNamesString, filename));
        end
    else
        % Show a warning and use the new options.
        msgid = "MATLAB:io:datastore:parquet:validation:ParameterResetDueToVariableNameChange";
        changedVariableNames = selectedParquetFileVariableNames(~isfound);
        changedVariableNamesString = join("    " + changedVariableNames, newline);
        filename = fs.FileInfo(1).Filename;
        warning(message(msgid, changedVariableNamesString, filename));
    end

    if reuseOldOpts
        opts = oldOpts;
    else
        opts = newOpts;
    end
end
