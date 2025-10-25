function compStrings = createCompressedPaths(pathStruct, origFileSep)
%createCompressedPaths    Create an object of class CompressedStrings to
%   store the file names in the output location.

%   Copyright 2023 The MathWorks, Inc.

    compStrings = matlab.io.datastore.internal.CompressedStrings(...
        pathStruct.Filenames,pathStruct.Folders,pathStruct.Extensions, origFileSep);
end