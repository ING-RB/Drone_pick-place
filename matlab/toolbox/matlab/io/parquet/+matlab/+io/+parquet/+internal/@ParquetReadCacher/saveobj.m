function S = saveobj(cacher)
%saveobj   Save-to-struct for ParquetReadCacher.

%   Copyright 2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = cacher.ClassVersion;

    % Public properties
    % Can't save the C++ reader so only save the filename instead.
    S.Filename                = cacher.Filename;
    S.FilteredRowGroups       = cacher.FilteredRowGroups;
    S.IsRowGroupFilteringDone = cacher.IsRowGroupFilteringDone;
    S.TableSchema             = cacher.TableSchema;
    S.ParquetFileRowFilter    = cacher.ParquetFileRowFilter;
end
