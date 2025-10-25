% This class is unsupported and might change or be removed without
% notice in a future version.

% This class reads in the first few lines of a text file, for display in the
% Current Folder Browser's preview.  This function is called when the user shows
% the preview from the CFB, so needs to be quick.

% Copyright 2021-2022 The MathWorks, Inc.

function s = textFilePreview(filename)
    arguments
        filename string {mustBeFile}
    end

    MAX_LINES = 10;
    MAX_LINES_BUFFER = MAX_LINES + 1;
    fid = fopen(filename, "r");
    s = "";
    try
        for idx = 1:MAX_LINES_BUFFER
            ln = fgetl(fid);
            if ~isequal(ln, -1)
                s(idx) = ln;
            end
        end
    catch
    end

    if length(s) == MAX_LINES_BUFFER
        % There's more than MAX_LINES lines, show ...
        s(end) = "...";
    end

    s = s';

    MAX_LEN = 75;
    longLines = find(strlength(s) > MAX_LEN);
    for idx = 1:length(longLines)
        s(longLines(idx)) = extractBefore(s(longLines(idx)), MAX_LEN) + "...";
    end

    if fid > 0
        fclose(fid);
    end
end
