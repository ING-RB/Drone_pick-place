function pio = introspectFile(fs, pioArgs)
%introspectFile   Introspect into the first file in the datastore and get
%   a ParquetImportOptions object.
%
%   Optionally provide any N-V args that should override detected ParquetImportOptions
%   parameters.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        fs  (1, 1) matlab.io.datastore.FileSet
        pioArgs.?matlab.io.parquet.internal.ParquetImportOptions
    end

    import matlab.io.parquet.internal.ParquetImportOptions
    import matlab.io.parquet.internal.detectParquetImportOptions
    import matlab.io.datastore.internal.ParquetDatastore.makeDefaultArrowTypeConversionOptions

    pioArgs = namedargs2cell(pioArgs);

    % Generate a copy of fs and reset it.
    fs = fs.copy();
    fs.reset();

    % Change the default ArrowTypeConversionOptions for ParquetDatastore to
    % avoid doing integer/logical promotion and fill with 0 or false instead.
    typeOpts = makeDefaultArrowTypeConversionOptions();
    defaultArgs = {"ArrowTypeConversionOptions", typeOpts};

    % Avoid detection if the FileSet is empty.
    if fs.NumFiles == 0
        pio = ParquetImportOptions(defaultArgs{:}, pioArgs{:});
    else
        % Detect ParquetImportOptions from the first file in the FileSet.
        pio = detectParquetImportOptions(nextfile(fs).Filename, defaultArgs{:}, pioArgs{:});
    end
end