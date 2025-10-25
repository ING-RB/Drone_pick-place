function cacher = loadobj(S)
%loadobj   Load-from-struct for ParquetReadCacher

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.parquet.internal.ParquetReadCacher

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > ParquetReadCacher.ClassVersion
            error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
        end
    end

    % Try to reconstruct the Reader object from the filename.
    try
        cacher = ParquetReadCacher(S.Filename);
    catch
        % Something went wrong during loading. If the original Parquet file
        % doesn't exist in the new location, then load without a warning.
        % The missing filename will trigger the AlternateFileSystemRoots
        % workflow on ParquetDatastore2.
        cacher = ParquetReadCacher();
        return;
    end

    % Set the other cached properties.
    cacher.FilteredRowGroups       = S.FilteredRowGroups;
    cacher.IsRowGroupFilteringDone = S.IsRowGroupFilteringDone;
    cacher.TableSchema             = S.TableSchema;
    cacher.ParquetFileRowFilter    = S.ParquetFileRowFilter;
end
