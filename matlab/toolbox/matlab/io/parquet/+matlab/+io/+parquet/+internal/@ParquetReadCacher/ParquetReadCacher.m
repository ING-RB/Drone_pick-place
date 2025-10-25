classdef ParquetReadCacher < handle ...
                           & matlab.mixin.Copyable
%ParquetReadCacher   Reads a Parquet file incrementally while caching the
%   reader object.
%
%   Applies some optimizations to make sure that RowFilter is only applied
%   at construction.
%
%   Also has some utilities to recover ParquetReader state after save-load.

%   Copyright 2022-2024 The MathWorks, Inc.

    properties (Transient)
        InternalReader
        TemporaryDownloadedFile % Required for HTTP/S support. Usually a RemoteToLocal object.
    end

    % Required to recover state after loading.
    properties
        Filename (1, 1) string = string(missing)
    end

    % Caches rowgroup filtering results so that rowgroup filtering doesn't
    % have to be re-done on every parquetread.
    properties
        FilteredRowGroups       (1, :) double  = double.empty(1, 0)
        IsRowGroupFilteringDone (1, 1) logical = false
        TableSchema             (0, :) = table.empty(0, 0)
        ParquetFileRowFilter    (1, 1) matlab.io.RowFilter = rowfilter(missing)
    end

    methods
        function cacher = ParquetReadCacher(Filename)

            import matlab.io.parquet.internal.validateParquetReadFilename
            import matlab.io.parquet.internal.makeParquetException

            if nargin == 0
                % Used in loadobj when there is no valid filename to use
                % after load.
                return;
            end

            try
                % Throws better error messages if an invalid Filename is provided.
                % Also downloads the Parquet file if an HTTP/S path is provided as
                % input.
                [cacher.Filename, cacher.TemporaryDownloadedFile] = validateParquetReadFilename(Filename);

                % Don't know which rowgroups to read yet, so start with
                % empty.
                % Make sure you use the "readRowGroupAtIndex", "readFullFile",
                % or "readall" methods on RowGroupParquetReader to avoid accidentially
                % incrementing its internal iteration index. Avoid using the
                % "read" method on RowGroupParquetReader for this reason.
                cacher.InternalReader = matlab.io.parquet.internal.RowGroupParquetReader(cacher.Filename, []);
            catch ME
                throw(makeParquetException(ME, Filename, "read"));
            end
        end

        function selectRowGroups(cacher, rowgroups)
            cacher.FilteredRowGroups = rowgroups;
            cacher.IsRowGroupFilteringDone = true;
        end
    end

    % Save-load metadata.
    properties (Access = private, Constant)
        % ClassVersion = 1 corresponds to the first release of ParquetReadCacher in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods (Hidden)
        S = saveobj(cacher);
    end

    methods (Hidden, Static)
        cacher = loadobj(S);
    end

    % Overload copyElement to make deep copies of the InternalReader object.
    methods (Access = protected)
        cacherCopy = copyElement(cacher);
    end
end
