function fileResult = checkSeeAlso(fileResult)
    %checkSeeAlso Verify the see also line conforms to help standards
    %   A = checkSeeAlso(A) Checks for correct see also heading (SeeAlsoFormat)
    %   and if see also section is present, will fill following properties:
    %   - SeeAlsoCorrect
    %   - SeeAlsoOnlyOneLine
    %   - SeeAlsoNoEndingPeriod
    %   - SeeAlsoCorrectNumItems

    %   Copyright 2021-2024 The MathWorks, Inc.

    if fileResult.HelpText == ""
        return;
    end

    %Getting out see also section
    seeAlso = fileResult.ParsedHelp.SeeAlso;
    if isempty(seeAlso)
        return;
    end
    seeAlsoStr = seeAlso.helpStr;
    seeAlsoTitle = seeAlso.title;
    seeAlsoHotlinked = fileResult.HelpProcess.hotlinkList(seeAlsoStr, fileResult.PathName, fileResult.FunctionName, false, fileResult.InClass);

    %Check correct format of seeAlso title
    fourSpaces = "    ";
    fileResult.Results.SeeAlsoCorrectFormat = matches(seeAlsoTitle, fourSpaces + "See also");

    if seeAlsoHotlinked ~= ""
        seeAlsoHotlinked = erase(seeAlsoHotlinked, letterBoundary("start") + 'and' + letterBoundary("end"));
        %Checks that see also is all on one line
        fileResult.Results.SeeAlsoOnlyOneLine = ~contains(seeAlsoHotlinked, newline + wildcardPattern + alphanumericsPattern(1,inf)); %should allow for one new line if followed by only whitespace, since that may occur at end of help string
        %Checks that see also does not end in a period
        fileResult.Results.SeeAlsoNoEndingPeriod = ~endsWith(seeAlsoHotlinked, "." + optionalPattern(whitespacePattern));
        seeAlsoItems = extractBetween(seeAlsoHotlinked, '>', '</a>');
        %Checks that number of see also items is correct
        fileResult.Results.SeeAlsoCorrectNumItems = numel(seeAlsoItems) >= fileResult.MinSeeAlsoItems & numel(seeAlsoItems) <= fileResult.MaxSeeAlsoItems;
    end
end
