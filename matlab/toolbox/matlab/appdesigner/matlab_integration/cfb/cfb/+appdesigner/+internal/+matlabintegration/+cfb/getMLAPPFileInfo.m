function fileInfo = getMLAPPFileInfo(filepath)
    % getMLAPPFileInfo Facade API for App CFB File Preview
    %
    % Retrieve the meta data and screeenshot of the App with filepath.
    % This is called by the matlab integration CFB  mlapp_preview app module 
    % when the user chooses MLAPP-File in CFB and click ... to show preview popup
    % 
    % Return File meta data plug ScreenshotURI field if the app has screenshot 
    % Return File meta data without ScreenshotURI field if the app has no screenshot

    % Copyright 2020 The MathWorks, Inc.

    mlappMetaDataReader = mlapp.internal.MLAPPMetadataReader(filepath);
    fileInfo = mlappMetaDataReader.readMLAPPMetadata();

    [screenshotBytes, ~] = mlappMetaDataReader.readMLAPPScreenshot();
    if(~isempty(screenshotBytes))
        fileInfo.ScreenshotURI = appdesigner.internal.application.ImageUtils.getImageDataURIFromBytes(screenshotBytes, 'uri');
    end
end