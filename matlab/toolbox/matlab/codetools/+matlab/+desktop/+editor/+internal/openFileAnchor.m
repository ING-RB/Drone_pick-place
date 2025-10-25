function openFileAnchor(filePath, anchorId)
    [status, fileAttribute] = fileattrib(filePath);
    if ~status
        error(message('MATLAB:open:noOpenFolder', filePath)); 
    end
    document = matlab.desktop.editor.openDocument(fileAttribute.Name);
    document.Opened;
    message.publish(strcat('/Hyperlinks/NavigateToInternalAnchor/', document.Editor.RtcId), anchorId);
end