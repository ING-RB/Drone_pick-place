function mediaInfo = getMediaInfo(fileName, imageId)
    % Read the content of the file
    fileContent = fileread(fileName);
    % Get the media information
    mediaInfo = matlab.internal.livecode.FileModel.getMediaInfo(fileContent, imageId);
end