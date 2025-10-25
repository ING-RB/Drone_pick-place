function tf = isEmptyFile(fid)
% Store the original position in the file.

%   Copyright 2019-2022 The MathWorks, Inc.

    originalFilePosition = ftell(fid);

    % Move to the end of the file ("eof").
    fseek(fid, 0, "eof");
    % If the position of the file pointer is 0
    % after moving to the end of the file,
    % then the file is empty.
    tf = ftell(fid) == 0;

    % Restore the original position in the file.
    fseek(fid, originalFilePosition, "bof");
end
