function [validFileNames, fileExtensions] = validateFileName(filename, extensions, lookupOnMATLABPath)
%VALIDATEFILENAME Validate the existence of a specified file.
%   Validate the existence of a file named FILENAME by searching through
%   the filesystem. First, check if FILENAME is a valid absolute or
%   relative path to a file. Otherwise, check for a file named FILENAME on
%   the MATLAB path.
%
%   varargin: Optionally, specify a list of file extensions to search for
%             as a cell array of character vectors.
%
%             For example, if FILENAME == 'myFile' and extensions == {'.txt', '.csv'},
%             then VALIDATEFILENAME will check for the existence of the following
%             files, in the order specified below:
%
%               1. 'myFile'
%               2. 'myFile.txt'
%               3. 'myFile.csv'
%
% VALIDATEFILENAME will return all file names matching the specified
% validation criteria as VALIDFILENAMES, along with their
% corresponding file extensions as FILEXTENSIONS.

%   Copyright 2016-2021 The MathWorks, Inc.

filename = convertCharsToStrings(filename);
if ispc
    filename = strip(filename,'right');
end
% Check if additional file extensions were provided. If so, generate
% additional file names for validation.
fileNamesToBeValidated = filename;
if nargin > 1
    extensions = convertCharsToStrings(extensions);
    extensions(~startsWith(extensions,'.')) = "." + extensions(~startsWith(extensions,'.'));
    [~, ~, ext] = fileparts(filename);
    if ext == ""
        additionalFileNames = filename + extensions;
        fileNamesToBeValidated = [filename, additionalFileNames];
    end
end

if nargin < 3
    lookupOnMATLABPath = true;
end

% Validate file names.
isFile = isfile(fileNamesToBeValidated);
validFileNames = fileNamesToBeValidated(isFile);
if any(~isFile,'all') && lookupOnMATLABPath
    validFileNames = [validFileNames(:); validateFileNameOnMATLABPath(fileNamesToBeValidated(~isFile))];
end

% If no valid files were found, then error.
if isempty(validFileNames)
    if numel(filename) > 1
        error(message('MATLAB:textio:textio:FileNotFound', filename(1)));
    else
        error(message('MATLAB:textio:textio:FileNotFound', filename));
    end
end


validFileNames = localUnique(validFileNames);
% Get file extensions of valid file names.
[paths, ~, fileExtensions] = fileparts(validFileNames);
hasNoPath = (strlength(paths)==0);
validFileNames(hasNoPath) = fullfile(cd,validFileNames(hasNoPath));
% Return only unique file names and extensions.
fileExtensions = cellstr(localUnique(fileExtensions));
validFileNames = cellstr(validFileNames);
end

function fn = validateFileNameOnMATLABPath(names)
[~, ~, ext] = fileparts(names);
fn = {};
for i = 1:numel(names)
    nTemp = validateFileNameOnMATLABPathScalar(names(i),ext(i));
    if ~isempty(nTemp)
        fn = [fn(:); {nTemp}];
    end
end
end

function fn = validateFileNameOnMATLABPathScalar(fileName,ext)
% "which" can be used to search for files with an extension
% on the MATLAB path.
if ~strlength(ext)==0
    tempFileName = which(fileName);
    if ~isempty(tempFileName)
        fn = tempFileName;
    else
        fn = '';
    end
else
    % "fopen" can be used to search for files without an extension
    % on the MATLAB path.
    fid = fopen(fileName);
    if fid ~= -1
        tempFileName = fopen(fid);
        fclose(fid);
        fn = tempFileName;
    else
        fn = '';
    end
end
end

function c = localUnique(c)
% Gets the lower triangular and removes the elements that have originals.
% This results in a stable unique that's fast for small numbers of elements
n = numel(c);
c(any((c(:)==c(:)')&((1:n)'>(1:n)),2)) = [];
c = c(:);
end
