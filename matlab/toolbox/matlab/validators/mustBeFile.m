function mustBeFile(Path)
%MUSTBEFILE Validate value points to a file
%   MUSTBEFILE(PATH) throws an error if PATH isn't a file.
%   MATLAB calls isfile to determine if a PATH is a file.
%
%   See also ISFILE.

%   Copyright 2020-2024 The MathWorks, Inc.

if ~matlab.internal.validation.util.isNontrivialText(Path)
    throwAsCaller(MException("MATLAB:validators:mustBeNonzeroLengthText", ...
        message("MATLAB:validators:nonzeroLengthText")));
end

tf = isfile(Path);

if ~all(tf, 'all')
    files = string(Path);
    throwAsCaller(matlab.internal.validation.util.createExceptionForMissingItems(files(~tf), ...
        'MATLAB:validators:mustBeFile'));
end

% LocalWords:  isfile validators
