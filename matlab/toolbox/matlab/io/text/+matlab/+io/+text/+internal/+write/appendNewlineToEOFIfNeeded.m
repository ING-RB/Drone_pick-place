function [isEmpty,endIsNewLine] = appendNewlineToEOFIfNeeded(filename, fid, writeMode, lineEnding)
% APPENDNEWLINETOEOFIFNEEDED Append line ending prior to end of file (if
% needed)

%   Copyright 2021-2022 The MathWorks, Inc.
    import matlab.io.text.internal.write.fileEndsWithNewLine
    import matlab.io.text.internal.write.appendNewLineToEndOfFile
    import matlab.io.text.internal.write.isEmptyFile

    endIsNewLine = false;
    isEmpty = isEmptyFile(fid);
    
    if writeMode == "append" && ~isEmpty
        endIsNewLine = fileEndsWithNewLine(fid, filename, lineEnding);
        if ~endIsNewLine
            appendNewLineToEndOfFile(fid, lineEnding);
        end
    end
end