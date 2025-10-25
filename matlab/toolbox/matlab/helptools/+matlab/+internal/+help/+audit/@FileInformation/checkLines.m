function fileResult = checkLines(fileResult)
    %checkLines Verify general standards pertaining to entire help text file
    %   A = checkLines(A) will take in a fileResult object and check
    %   the following:
    %   - Whether the number of lines is <= the maximum
    %   - Whether all lines are under the maximum length
    %   - Whether there is trailing whitespace
    %   - Whether tabs are used in the help text

    %   Copyright 2021-2024 The MathWorks, Inc.

    if fileResult.HelpText == ""
        return;
    end
    h = fileResult.HelpText;
    InheritedLine = getString(message('MATLAB:introspective:displayHelp:HelpInheritedFromSuperclass','[\w\./]+', '[\w\./]+'));
    h = regexprep(h, InheritedLine, newline);
    h = string(h);
    lines = splitlines(h);
    numRows = numel(lines);
    fileResult.Results.UnderMaximumNumLines = numRows <= fileResult.MaxNumLines; %this may be updated to depend on whether there is a reference page
    lineLength = max(arrayfun(@matlab.internal.display.wrappedLength, lines));
    fileResult.Results.UnderMaximumLineLength = lineLength <= fileResult.MaxLineLength;
    numTrailing = numel(extract(h, asManyOfPattern(' ', 1) + newline)) - numel(extract(h, newline + " " + newline));
    fileResult.Results.NoTrailingWhitespace = numTrailing == 0;
    fileResult.Results.NoTabs = ~contains(h, fileResult.Tab);
end

