function schema = computeSchema(fs, pio)
%computeSchema   Introspect into the first file in the datastore to get the
%   current schema.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        fs  (1, 1) matlab.io.datastore.FileSet
        pio (1, 1) matlab.io.parquet.internal.ParquetImportOptions
    end

    import matlab.io.parquet.internal.parquetread2

    % To get exactly the right zoned datetime empty state, we must actually
    % read from the first file in the dataset.
    fs = fs.copy();
    fs.reset();

    if fs.NumFiles == 0
        % Empty case, no files in FileSet.
        % Return the empty that the TableBuilder can generate. NOTE that
        % this doesn't account for zoned datetimes or ordinal categoricals correctly.
        schema = pio.TabularBuilder.buildEmpty();
        return;
    end

    % Do a zero-rowgroups read from the first file in the dataset to get
    % the schema. This accounts for empty zoned datetimes and empty
    % ordinal categoricals correctly.
    filename = fs.nextfile().Filename;
    schema = parquetread2(filename, pio, RowGroups=double.empty(0, 1));
end
