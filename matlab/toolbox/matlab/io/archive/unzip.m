function varargout = unzip(zipFilename, outputDir, opts)

arguments(Input)
    zipFilename {mustBeTextScalar, mustBeNonzeroLengthText};
    outputDir {mustBeTextScalar} = '.';
    opts.Password {mustBeTextScalar, mustBeNonzeroLengthText};
end

nargoutchk(0,1);

if ~isfield(opts, "Password")
    opts.Password = missing;
end

[zipFilename,outputDir] = convertStringsToChars(zipFilename,outputDir);

cleanUpUrl = [];

% Storing the url, since zipFilename will get updated with temp filename if zipFilename is a url.
urlFilename = zipFilename;

% Argument parsing.
[zipFilename, outputDir, url, tempFilename] = matlab.io.internal.archive.parseUnArchiveInputs( ...
    mfilename, zipFilename, {'zip'}, 'ZIPFILENAME', outputDir);

if url && ~isempty(tempFilename) && exist(tempFilename,'file')
    cleanUpUrl = tempFilename;
end

% Extract ZIP contents.
try
    cleanUpObject = onCleanup(@()cellfun(@(x)x(), {@()delete(cleanUpUrl)}));

    % Passing the fourth argument empty since this is where internal teams can specify the list of files to extract.
    files = matlab.io.internal.archive.core.builtin.extractArchive(zipFilename, outputDir, 'zip', '', convertStringsToChars(opts.Password));
catch extractArchiveException
    if url && extractArchiveException.identifier == "MATLAB:io:archive:unzip:invalidZipFile"
        error(message("MATLAB:io:archive:unzip:invalidZipFile", urlFilename));
    else
        throwAsCaller(extractArchiveException);
    end
end

if nargout == 1
    files = matlab.io.internal.archive.cleanupWindowsPathname(files);
    varargout{1} = files;
end

%   Copyright 1984-2024 The MathWorks, Inc.
