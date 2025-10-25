function validatedFullFileName = getValidatedFile(inputFile, fileExtension)
% GETVALIDATEDFILE - The function takes a user-inputted file name,
% validates the file name WITHOUT existence checks, and returns a valid full
% file name.

% INPUTS: 
%   inputFile {str or char} - file of any of the following forms.  If inputFile
%   is not of these forms, validation will fail.
%        'myNewFile'
%        'myNewFile.EXTENSION'
%        'C:/username/myNewFile'
%        'C:/username/myNewFile.EXTENSION'
%   fileExtension {str or char} - e.g. '.mlapp' or '.fig'
%
% OUTPUT:
%   validatedFullFileName {char} - validated full file name with extension.

% Copyright 2020-2024 The MathWorks, Inc.

% The inputted file must be char or scalar string only.
if ~ischar(inputFile) && ~(isstring(inputFile) && isscalar(inputFile))
    error(message('MATLAB:appdesigner:appdesigner:InvalidInput'));
end
inputFile = char(inputFile);

[filepath, file, ext] = fileparts(inputFile);

% File name cannot be a keyword
if iskeyword(file)
    error(message('MATLAB:appdesigner:appdesigner:FileNameFailsIsKeyword'));
end

% File name must use valid characters
if ~isvarname(file)
    error(message('MATLAB:appdesigner:appdesigner:FileNameFailsIsVarName', file, namelengthmax));
end

% If extension is not included, add it.  If extension is included and is
% wrong, error.
if isempty(ext)
    ext = fileExtension;
elseif ~strcmp(ext, fileExtension)
    error(message('MATLAB:appdesigner:appdesigner:InvalidGeneralFileExtension', inputFile, fileExtension));
end

% If no path was included, use cd as the path.  If path was included but
% doesn't exist, error.
if isempty(filepath)
    filepath = cd;
elseif ~isfolder(filepath)
    error(message(('MATLAB:appdesigner:appdesigner:InvalidFilePath')));
end

% Combine file parts to make the validated full file name.
validatedFullFileName = fullfile(filepath,[file ext]);

end