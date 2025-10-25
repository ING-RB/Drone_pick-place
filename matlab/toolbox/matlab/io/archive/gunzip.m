function varargout = gunzip(files,dir)

narginchk(1,2);
nargoutchk(0,1);

% rootDir is always ''
if nargin < 2
    dir = {};
end

[files,dir] = convertStringsToChars(files,dir);

dirs = [{''}, dir];

% Check input arguments.
[files, rootDir, outputDir, dirCreated] = matlab.io.internal.archive.checkFilesDirInputs(mfilename, files, dirs{:});

try
    % Check files input for URL .
    [files, url, urlFilename] = checkFilesURLInput(files, {'gz'},'FILES',mfilename);

    if ~url
        % Get and gunzip the files
        entries = matlab.io.internal.archive.getArchiveEntries(files, rootDir, mfilename);

        % Check if absolute path of unzipped files collide with archive names
        if isempty(dirCreated) % collision not possible if unzipping into new folder
            destinationIsSameAsSource = ismember(fullfile({entries.file}), fullfile(rootDir,outputDir,files));

            if ispc
                % On Windows, trailing ".." is the same as no extension as the OS
                % automatically strips the trailing ".." away
                noExtRegExp = '\.[^.]';
            else
                % On Unix, anything (including ".") after "." is a valid extension
                noExtRegExp = '\.';
            end

            srcHasNoExtension = cellfun(@isempty, regexp({entries.entry},noExtRegExp,'once'));

            isCollidedFile = destinationIsSameAsSource & srcHasNoExtension;
            if any(isCollidedFile)
                error(message('MATLAB:io:archive:gunzip:destinationSameAsSource',...
                    strjoin({entries(isCollidedFile).file}, ', ')));
            end
        end

        try
            names = matlab.io.internal.archive.core.builtin.uncompressgz({entries.file}, outputDir, false);
        catch extractGunzipException
            throwAsCaller(extractGunzipException);
        end
    else
        % Gunzip the URL
        names = gunzipURL(files{1}, outputDir, urlFilename);
    end

    % Return the names if requested
    if nargout == 1
        varargout{1} = names;
    end
catch exception
    if ~isempty(dirCreated)
        rmdir(dirCreated, 's');
    end
    rethrow(exception);
end
%--------------------------------------------------------------------------
function [files, url, urlFilename] = ...
    checkFilesURLInput(inputFiles, validExtensions, argName, fcnName)

% Assign the default return values
files = inputFiles;
url = false;
urlFilename = '';

if numel(inputFiles) == 1 && isempty(strfind(inputFiles{1}, '*')) && ...
        ~isdir(inputFiles{1})

    % Check for a URL in the filename and for the file's existence
    [fullFileName, url] = matlab.io.internal.archive.checkFilename(inputFiles{1}, validExtensions, fcnName, argName);
    if url
        % Remove extension
        [~, urlFilename, ext] = fileparts(inputFiles{1});
        if ~any(strcmp(ext,{'.tgz','.gz'}))
            % Add the extension if the URL file is not .gz or .tgz
            % The URL may not be a GZIPPED file, but let pass
            urlFilename = [urlFilename ext];
        end
        files = {char(fullFileName)};
    end
end

%--------------------------------------------------------------------------
function names = gunzipURL(filename, outputDir, urlFilename)
try
    gunzipFilename = fullfile(outputDir,urlFilename);
    names = matlab.io.internal.archive.core.builtin.uncompressgz(filename, gunzipFilename, true);
    % Filename is temporary for URL
    delete(filename);
catch exception
    if ~isequal('MATLAB:io:archive:gunzip:notGzipFormat', exception.identifier)
        delete(filename);
        throw(exception);
    else
        names{1} = fullfile(outputDir, urlFilename);
        if exist(names{1},'file') == 2
            delete(filename);
            error(message('MATLAB:io:archive:gunzip:urlFileExists', names{ 1 }));
        else
            copyfile(filename, names{1})
            delete(filename);
        end
    end
end

% Copyright 2004-2023 The MathWorks, Inc.
