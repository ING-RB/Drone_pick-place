function fileNameObj = getFileFromURL(uri)
%GETFILEFROMURL Detects whether the input filename is a URL and downloads
%file from the URL (HTTPS, AMAZON S3, MICROSOFT AZURE and HADOOP). It
%returns either an object or the name of the locally downloaded file.

%   Copyright 2007-2021 The MathWorks, Inc.

    if ~matlab.io.internal.vfs.validators.hasIriPrefix(uri)
        fileNameObj = uri;
        return;
    end

    try
        fileNameObj = matlab.io.internal.vfs.stream.RemoteToLocal(uri);
    catch ME
        error(message('MATLAB:imagesci:getFileFromURL:urlRead', uri, ME.message));
    end

    if strcmpi(fileNameObj.RemoteFileName, fileNameObj.LocalFileName)
        % At this point if the RemoteFileName and LocalFileName are the same,
        % it indicates that an invalid URL has been passed as an input.
        % Throw an error messaage.
        msg = message('MATLAB:imagesci:getFileFromURL:invalidURL');
        error(message('MATLAB:imagesci:getFileFromURL:urlRead', uri, msg.getString()));
    end
end
