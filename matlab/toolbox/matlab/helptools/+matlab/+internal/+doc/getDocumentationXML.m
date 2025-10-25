function xmlString = getDocumentationXML(filePath)
    %getDocumentationXML Extracts the documentation content from the live code file to be displayed in doc.
    %   getDocumentationXML(topic) topic is the file path of the live code file.

    %   Copyright 2017-2023 The MathWorks, Inc.

    xmlString = string.empty;
    if matlab.desktop.editor.EditorUtils.isLiveCodeFile(filePath)
        xmlString = string(matlab.internal.livecode.FileModel.getDocumentationXml(filePath));
    end
end
