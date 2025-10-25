function summary = getSummary (filePath)
    % matlab.desktop.editor.internal.getSummary - gives the helptext of the given filepath.
    % matlab.desktop.editor.internal.getSummary(FILEPATH)
    % It gives the H1 line of the helptext.
    % This helptext is used in the Current folder browser preview for editor files.

    % Copyright 2022 The MathWorks, Inc.
    h = help(filePath, '-noDefault');
    summary = extractBefore(h, newline);
end