function location = getLocation(pds)
%getLocation   Location of files for the HadoopLocationBased implementation
%   in ParquetDatastore.

%   Copyright 2022 The MathWorks, Inc.

    location = pds.getUnderlyingFileDatastore().FileSet;
end
