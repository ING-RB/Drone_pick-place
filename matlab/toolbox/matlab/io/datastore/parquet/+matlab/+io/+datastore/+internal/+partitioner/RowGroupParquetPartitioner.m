classdef RowGroupParquetPartitioner
%RowGroupParquetPartitioner   Compatibility shim to intercept loadobj of
%   R2022a and previous ParquetDatastore.
%
%   See matlab.io.datastore.ParquetDatastore.loadobj.

%   Copyright 2022 The MathWorks, Inc.

    properties
        FileSet
        RowGroups
    end

    methods (Static)
        function obj = loadobj(S)
            obj = matlab.io.datastore.internal.partitioner.RowGroupParquetPartitioner();

            fs = matlab.io.datastore.internal.makeFileSet(S.FileSet);

            filenames = fs.FileInfo.Filename;
            numreps = cellfun(@numel, S.FileIndices, UniformOutput=true);
            numreps = [1; numreps];
            repIndex = cumsum(numreps);
            repIndex(end) = [];
            filenames = filenames(repIndex);

            obj.FileSet = matlab.io.datastore.FileSet(filenames, ...
                AlternateFileSystemRoots=fs.AlternateFileSystemRoots);
            obj.RowGroups = cellfun(@(x) reshape(x, [], 1), S.RowGroups, UniformOutput=false);
        end
    end
end