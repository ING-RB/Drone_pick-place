function tf = isSupportedIRI(filenames)
%isSupportedIRI    Verify that all input filenames represent supported IRIs

%   Copyright 2016-2020 The MathWorks, Inc.

tf = strncmpi(filenames,'s3://', 5) | ...
     strncmpi(filenames, 'wasb://', 7) |...
     strncmpi(filenames, 'wasbs://', 8) | ...
     strncmpi(filenames, 'cloudmock://', 12);
end