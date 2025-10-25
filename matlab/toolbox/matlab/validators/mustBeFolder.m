function mustBeFolder(Path)
%MUSTBEFOLDER Validate that input path points to a folder
%   MUSTBEFOLDER(PATH) throws an error if PATH doesn't point to a folder.
%   MATLAB calls isfolder to determine if PATH points to a folder.
%
%   See also ISFOLDER.

%   Copyright 2020-2024 The MathWorks, Inc.

if ~matlab.internal.validation.util.isNontrivialText(Path)
    throwAsCaller(MException("MATLAB:validators:mustBeNonzeroLengthText", ...
        message("MATLAB:validators:nonzeroLengthText")));
end

tf = isfolder(Path);

if ~all(tf, 'all')
    files = string(Path);
    throwAsCaller(matlab.internal.validation.util.createExceptionForMissingItems(files(~tf), ...
        'MATLAB:validators:mustBeFolder'));
end

% LocalWords:  isfolder validators
