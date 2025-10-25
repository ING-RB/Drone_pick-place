function isChecksumEqual = compareFileChecksums(fileOnDisk, temporaryFile)
%matlab.desktop.editor.internal.compareFileChecksums Compares checksum two files.
%   matlab.desktop.editor.internal.compareFileChecksums(FILEONDISK, TEMPORARYFILE) compares the checksums
%   of two files specified by FILEONDISK and TEMPORARYFILE. FILEONDISK is the absolute path
%   of the file on disk, and TEMPORARYFILE is the absolute path of a temporary file.
%   Returns ISCHECKSUMEQUAL as a logical value indicating whether the checksums are equal and deletes TEMPORARYFILE.
%
%   Note: This function is unsupported and might change or be removed without notice in a future version.

%   Copyright 2025 The MathWorks, Inc.

    arguments (Input)
        fileOnDisk {mustBeFile}
        temporaryFile {mustBeFile}
    end

    arguments (Output)
        isChecksumEqual (1,1) logical
    end

    cleanupObj = onCleanup(@() delete(temporaryFile));

    digester = matlab.internal.crypto.BasicDigester('Blake-2b');
    fileOnDiskChecksum = digester.computeFileDigest(fileOnDisk);
    temporaryFileChecksum = digester.computeFileDigest(temporaryFile);

    isChecksumEqual = isequal(fileOnDiskChecksum, temporaryFileChecksum);
end
