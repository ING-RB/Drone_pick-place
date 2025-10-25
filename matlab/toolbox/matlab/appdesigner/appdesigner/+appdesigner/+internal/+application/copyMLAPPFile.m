function copyMLAPPFile(fullFileName, newFullFileName)
    % Copies .mlapp file
    % Normal copyfile is naive, straight copy, so file name does not match class name
    %
    % Copyright 2022 The MathWorks, Inc.

    srcMlappFile = fullFileName;
    dstMlappFile = newFullFileName;

    % Get code from file
    reader = appdesigner.internal.serialization.FileReader(srcMlappFile);
    codeText = reader.readMATLABCodeText();
    appDataToSerialize = reader.readAppDesignerData();
    metaData = reader.readAppMetadata();

    % Replace class definition and constructor with new name
    [~,srcFileName] = fileparts(srcMlappFile);
    [~,dstFileName] = fileparts(dstMlappFile);
    codeText = strrep(codeText,"classdef " + srcFileName, "classdef " + dstFileName);
    codeText = strrep(codeText,"function app = " + srcFileName, "function app = " + dstFileName);
    codeText = convertStringsToChars(codeText);

    % Update appData
    appDataToSerialize.code.ClassName = dstFileName;

    % Update metadata
    metaData.Name = dstFileName;

    % Write new file with updated code
    writer = appdesigner.internal.serialization.FileWriter(dstMlappFile);
    writer.createOrOverwriteTargetFile();
    writer.writeMLAPPFile(codeText, appDataToSerialize, metaData);
end