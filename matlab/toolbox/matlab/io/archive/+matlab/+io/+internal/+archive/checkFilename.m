function [fullfilename, isURL] = checkFilename(filename, validExtensions, functionName, argumentName)
%CHECKFILENAME Check validity of a filename.
%
%   [FULLFILENAME ISURL] = CHECKFILENAME(FILENAME, VALIDEXTENSIONS, FUNCTIONNAME, ARGUMENTNAME)
%   checks the validity of the FILENAME for reading data and issues a
%   formatted error if the FILENAME is invalid. FULLFILENAME is a scalar
%   string and the absolute pathname of the file. If FILENAME is a URL,
%   FULLFILENAME is the absolute path to a temporary file copied from the
%   URL location and ISURL is TRUE; otherwise ISURL is FALSE. All input
%   arguments are required.
%
%   FILENAME can be a MATLABPATH relative partial pathname. If the file is
%   not found in the current working directory, CHECKFILENAME searches down
%   MATLAB's search path. The FILENAME must exist with read permission.
%   FILENAME may be a URL address. If so, it must include the protocol type
%   (e.g., "https://").
%
%   VALIDEXTENSIONS is a string array containing extensions with the "."
%   character. It may be empty.
%
%   FUNCTIONNAME is a string containing the function name to be used in
%   the formatted error message.
%
%   ARGUMENTNAME is a string indicating the argument name that is being
%   checked and is used in the formatted error message.
%
%   Example Usage:
%
%   import matlab.io.internal.archive.checkFilename
%   [fullfilename, isurl] = checkFilename("test.zip", ".zip", "unzip", "filename");

%   Copyright 2004-2023 The MathWorks, Inc.

arguments
    filename(1, 1) string
    validExtensions(1, :) string
    functionName(1, 1) string
    argumentName(1, 1) string
end

if strlength(filename) == 0 % must be nonempty text
    error(message("MATLAB:io:archive:checkfilename:expectedNonEmpty", upper(functionName), argumentName));
end


% If the filename contains a URL string, download the remote file to a
% temporary file.
protocol = extractBefore(filename, "://");
if ~ismissing(protocol)
    isURL = true;
    fullfilename = downloadArchiveFile(protocol, filename, functionName);
else
    isURL = false;
    fullfilename = validateLocalFilename(filename, validExtensions, functionName);
end
end

%--------------------------------------------------------------------------
function fullfilename = downloadArchiveFile(protocol, url, functionName)
% Downloads the URL to a temporary file and returns the absolute path to
% the temporary file.

% Get the extension to append
[~, ~, ext] = fileparts(url);
tempfilename = strcat(tempname, ext);
protocol = lower(protocol);
fullfilename = missing;

try
    if protocol == "https" || protocol == "http"
        fullfilename = websave(tempfilename, url);
    elseif protocol == "file"
        fullfilename = matlab.internal.writeFromFileUrl(url, tempfilename);
    elseif protocol == "ftp"
        fullfilename = matlab.internal.writeFromFtpUrl(url, tempfilename);
    end
catch
    if exist(tempfilename, "file")
        delete(tempfilename);
    end
    error(message("MATLAB:io:archive:checkfilename:urlwriteError",...
        upper(functionName), url))
end

if ismissing(fullfilename)
    % The URL supplied has an unsupported protocol
    error(message("MATLAB:io:archive:checkfilename:urlwriteError",...
        upper(functionName), url));
end
end

%--------------------------------------------------------------------------
function fullfilename = validateLocalFilename(filename, validExtensions, functionName)

% Specify the encoding as "UTF-8" to avoid encoding detection. The
% opened file handle is never used to read any data from the file, so
% it's fine to specify a "dummy" encoding. In other words, the fid
% is only used to determine if the file exists.
fid = fopen(filename, "r", "n", "UTF-8");

if (fid == -1)
    % Append each valid extensions to filename and try opening a file.
    fid = findFileWithExtension(filename, validExtensions);
    if (fid == -1)
        % Still failed to open a file. Error.
        throwFileNotFoundError(filename, functionName);
    end
end

% Get the absolute filepath
fullfilename = fopen(fid);

% Must close the file to avoid leaving an open file handle around.
fclose(fid);

% Return the full pathname if not in the current working directory
end

%--------------------------------------------------------------------------
function fid = findFileWithExtension(filename, validExtensions)
% We failed to open the filename specified by filename in read-mode.
% Append each extension in validExtensions to filename and try opening
% a file in read-mode. If a file is opened successfully, stop and
% return the file identifier. If no file can be opnend, return -1 as
% the file identifier.
%
% NOTE: If fid ~= -1, the calling function is responsible for closing
% the file handle.

extensions = [lower(validExtensions) upper(validExtensions)];

% Loop through the list of valid extensions. Append each one to the
% input filename and try opening the file.
for ii = 1:numel(extensions)
    name = strcat(filename, ".", extensions(ii));

    fid = fopen(name, "r", "n", "UTF-8");
    if fid ~= -1
        % We found a file
        break;
    end
end
end

%--------------------------------------------------------------------------
function throwFileNotFoundError(filename, functionName)
functionName = upper(functionName);
if exist(filename, "file") == 2
    % Check to verify NOT a MATLAB file
    if ~(exist(strcat(filename, ".m"), "file") == 2 || exist(strcat(filename, ".M"), "file") == 2)
        % File exists without read mode
        error(message("MATLAB:io:archive:checkfilename:invalidFileMode", functionName, filename));
    end
end
% File does not exist
error(message("MATLAB:io:archive:checkfilename:invalidFilename", functionName, filename));
end
