function tf = isfullfile(pds)
%isfullfile   Declare RowGroup/File reading mode for the HadoopLocationBased implementation
%   in ParquetDatastore.

%   Copyright 2022 The MathWorks, Inc.

    tf = isequaln(pds.ReadSize, 'file');
end
