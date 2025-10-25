function appendNewLineToEndOfFile(fid, lineEnding)
% APPENDNEWLINETOENDOFFILE Append a new line ending to the file.

%   Copyright 2019-2022 The MathWorks, Inc.

    originalFilePosition = ftell(fid);

    % Move to the end of the file ("eof").
    fseek(fid, 0, "eof");
    % Append a new line ending to the end of the file.
    fprintf(fid, "%s", string(lineEnding));

    % Restore the original position in the file.
    fseek(fid, originalFilePosition, "bof");
end
