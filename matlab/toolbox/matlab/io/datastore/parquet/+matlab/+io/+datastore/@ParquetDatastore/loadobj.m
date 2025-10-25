function obj = loadobj(S)
%loadobj   load-from-struct for ParquetDatastore

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.ParquetDatastore

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > ParquetDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    else
        % We're loading R2022a and previous ParquetDatastore. This was
        % originally stored as an object in a MAT file, but the loadobj
        % infrastructure will fail to resolve ParquetDatastore2 properties with
        % ParquetDatastore2 and therefore load it as a struct.

        % Print a warning that the ParquetDatastore will be reset() on
        % load.
        msgid = "MATLAB:io:datastore:parquet:validation:LoadobjFromLegacyParquetDatastore";
        warning(message(msgid));

        obj = parquetDatastore(S.Partitioner.FileSet, ReadSize=S.ReadSize);
        obj = loadFromStructPreR2022b(obj, S);
        return;
    end

    % Reconstruct the object.
    obj = ParquetDatastore({});
    obj.UnderlyingDatastore = S.UnderlyingDatastore;

    if isfield(S, "PartitionMethodDerivedFromAuto")
        obj.PartitionMethodDerivedFromAuto = S.PartitionMethodDerivedFromAuto;
        % else
        %     by-default
        %     PartitionMethod="auto" and
        %     PartitionMethodDerivedFromAuto=true;
    end

    % If the underlying Reader object loaded with a missing filename, then the original
    % Parquet files were not found on load. Reset the datastore to ensure
    % that the datastore stack uses the AlternateFileSystemRoots code path
    % from FileSet and uses mapped files instead of the original files.
    cls = "matlab.io.datastore.internal.RepeatedDatastore";
    rptds = getUnderlyingDatastore(obj.UnderlyingDatastore, cls);
    if ~isempty(rptds) && ~isempty(rptds.CurrentReadData) && ismissing(rptds.CurrentReadData.Filename)
        obj.UnderlyingDatastore.reset();
    end
end
