function varargout = zip(zipFilename,files,rootDir, opts)

arguments(Input)
    zipFilename {mustBeTextScalar, mustBeNonzeroLengthText};
    files {mustBeText, mustBeNonzeroLengthText};
    rootDir (1,:) string = '';
    opts.Password {mustBeTextScalar, mustBeNonzeroLengthText};
    opts.EncryptionMethod {mustBeTextScalar, mustBeNonzeroLengthText};
end

nargoutchk(0,1);

encryptionMethodPresent = isfield(opts, "EncryptionMethod");
passwordPresent = isfield(opts, "Password");
passwordAndEncryptionMethodPresent = false;

if encryptionMethodPresent
    if ispc||ismac
        % In general, aes-128 & aes-256 are the documented methods but we are being permissive 
        % about other uses (e.g. with and without hyphens, upper and lower case)
        mustBeMember(lower(opts.EncryptionMethod),["zipcrypto", "aes-128", "aes128", "aes-256", "aes256"]);
    else
        % In Linux, zipcrypto is the only supported encryption method.
        mustBeMember(lower(opts.EncryptionMethod),"zipcrypto");
    end
    
    % Rename encryption methods for 3p/libarchive.
    if strcmpi(opts.EncryptionMethod,'ZipCrypto')
        opts.EncryptionMethod = 'zipcrypt';
    elseif strcmpi(opts.EncryptionMethod,'AES-128') | strcmpi(opts.EncryptionMethod,'AES128')
        opts.EncryptionMethod = 'aes128';
    elseif strcmpi(opts.EncryptionMethod,'AES-256') | strcmpi(opts.EncryptionMethod,'AES256')
        opts.EncryptionMethod = 'aes256';
    end
end

% xor returns true when either of the two inputs is true.
% As we need both password and encryption method to zip the files, passing
% either of them should be an error.
if xor(encryptionMethodPresent, passwordPresent)
    if ~encryptionMethodPresent
        eid = sprintf('MATLAB:%s:missingEncryptionMethod', mfilename);
        error(eid,'%s',getString(message('MATLAB:io:archive:parseArchiveInputs:missingEncryptionMethod')));
    else
        eid = sprintf('MATLAB:%s:missingPassword', mfilename);
        error(eid,'%s',getString(message('MATLAB:io:archive:parseArchiveInputs:missingPassword')));
    end
end

if encryptionMethodPresent && passwordPresent
    passwordAndEncryptionMethodPresent = true;
end

[zipFilename,files,rootDir] = convertStringsToChars(zipFilename,files,rootDir);

% Parse arguments.
[files, rootDir, zipFilename] =  ...
    matlab.io.internal.archive.parseArchiveInputs(mfilename, zipFilename,  files, rootDir);

% Create the archive
try
    entries = matlab.io.internal.archive.getArchiveEntries(files, rootDir, mfilename, true);
    matlab.io.internal.archive.checkDuplicateEntries(entries, mfilename);
    entries = matlab.io.internal.archive.filterOutArchiveFile(entries, zipFilename, mfilename);
    matlab.io.internal.archive.checkEmptyEntries(entries, mfilename);
	if passwordAndEncryptionMethodPresent == true 
		archive = matlab.io.internal.archive.core.builtin.createArchive(zipFilename,{entries.file},{entries.entry},mfilename, convertStringsToChars(opts.Password), opts.EncryptionMethod);
	else
		archive = matlab.io.internal.archive.core.builtin.createArchive(zipFilename,{entries.file},{entries.entry},mfilename);
	end
catch exception
    throw(exception);
end

if nargout == 1
    varargout{1} = archive;
end

% Copyright 1984-2024 The MathWorks, Inc.

