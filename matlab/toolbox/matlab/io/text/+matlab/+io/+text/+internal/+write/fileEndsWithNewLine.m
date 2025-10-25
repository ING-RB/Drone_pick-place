function tf = fileEndsWithNewLine(fid, fileName, lineEnding)
% FILEENDSWITHNEWLINE Check whether file ends with line ending character

%   Copyright 2019-2022 The MathWorks, Inc.

    import matlab.io.text.internal.write.isEmptyFile
    import matlab.io.internal.vfs.validators.isIRI

    tf = true;
    if isIRI(fileName) && startsWith(fileName, "hdfs","IgnoreCase",true)
        % HDFS has no seek capability, return from here
        return;
    end

    lineEndingLength = strlength(lineEnding);

    if ~isEmptyFile(fid)

        % Store the original position in the file.
        originalFilePosition = ftell(fid);

        % Move to length of line ending bytes before the end of the
        % file ("eof").
        fseek(fid, -lineEndingLength, "eof");

        % Read the last line ending byte(s) from the file.
        lastBytes = fread(fid, lineEndingLength,"uint8=>char")';
        tf = strcmp(lastBytes,lineEnding);

        % Check if the last byte(s) are supported new line characters.
        % Restore the original position in the file.
        fseek(fid, originalFilePosition, "bof");
    end
end
