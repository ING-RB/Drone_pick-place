classdef FullFileParquetPartitioner
%FullFileParquetPartitioner   Compatibility shim to intercept loadobj of
%   R2022a and previous ParquetDatastore.
%
%   See matlab.io.datastore.ParquetDatastore.loadobj.

%   Copyright 2022 The MathWorks, Inc.

    properties
        FileSet
    end

    methods (Static)
        function obj = loadobj(S)
            obj = matlab.io.datastore.internal.partitioner.FullFileParquetPartitioner();

            fs = matlab.io.datastore.internal.makeFileSet(S.FileSet);

            obj.FileSet = fs;
        end
    end
end