function localFile = makeLocalFile(filename)
    % The MATLAB xslt function does not support deep VFS adoption, so
    % always create a local temporary file copy if the specified
    % filename refers to a remote location like S3, WASBS, or HTTP(S).

    % Copyright 2024 The MathWorks, Inc.
    localFile = matlab.io.internal.filesystem.tempfile.tempFileFactory(filename);
    localFile.createLocalCopy();
end
