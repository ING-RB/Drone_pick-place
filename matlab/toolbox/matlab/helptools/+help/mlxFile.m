function helpContent = mlxFile(fullPath, justH1)
    %mlxFile Provides the help string to display in the command window for live functions.
    %   mlxFile(fullPath) Uses fullpath of the live function file and reads the documentation part.

    %   Copyright 2015-2022 The MathWorks, Inc.
    if nargin < 2
        justH1 = false;
    end

    % Get XML string from MLX file
    xmlString = string(matlab.internal.livecode.FileModel.getDocumentationXml(fullPath));
    if xmlString == ""
        helpContent = getPlaceholderHelpContent(fullPath, justH1);
        return
    end

    % Construct XML document
    import matlab.io.xml.dom.*;
    p = Parser;
    document = parseString(p, xmlString);

    % Construct Help string, starting with H1 line
    [~, fileName] = fileparts(fullPath);
    purpose = document.getElementsByTagName("purpose").item(0).TextContent;
    helpContent = " " + fileName + "   " + deblank(purpose) + newline;

    if justH1
        return
    end

    % Syntax
    syntax = document.getElementsByTagName("syntax").item(0).TextContent;
    helpContent = helpContent + "   " + syntax + newline + newline;

    % Description
    description = document.getElementsByTagName("descriptionText").item(0).TextContent;
    if strip(description) ~= ""
        descriptionWrapped = string(matlab.internal.display.printWrapped(description, 76));
        descriptionArray = "    " + splitlines(descriptionWrapped);
        description = join(descriptionArray, newline);
        helpContent = helpContent + description + newline;
    end

    % Reference link
    linkCharStr = getString(message("MATLAB:helpUtils:displayHelp:ReferencePageFor", fileName));
    referenceLink = string(matlab.internal.help.createMatlabLink("doc", fileName, linkCharStr));
    helpContent = helpContent + "    " + referenceLink + newline;

    helpContent = char(helpContent);
end


function placeholderHelpContent = getPlaceholderHelpContent(fullPath, justH1)
    % If an MLX file does not have the necessary documentation object,
    % then generate default content now
    [~, fileName] = fileparts(fullPath);
    fileType = matlab.internal.help.sourceFileType(fullPath);

    if fileType == "Function"
        defaultMessage = matlab.internal.help.formatHelpTextLine(getString(message("MATLAB:helpUtils:displayHelp:IsALiveFunction", fileName)));
    else
        defaultMessage = matlab.internal.help.formatHelpTextLine(getString(message("MATLAB:helpUtils:displayHelp:IsALiveScript", fileName)));
    end

    if justH1
        placeholderHelpContent = defaultMessage;
    else
        linkCharStr = getString(message("MATLAB:helpUtils:displayHelp:OpenInLiveEditor"));
        openInLiveEditorMessage = matlab.internal.help.createMatlabCommandWithTitle(matlab.internal.display.isHot, linkCharStr, "edit", fileName);

        placeholderHelpContent = [defaultMessage newline openInLiveEditorMessage];
    end
end
