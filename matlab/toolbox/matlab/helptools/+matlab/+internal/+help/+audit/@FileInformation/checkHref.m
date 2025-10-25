function fileResult = checkHref(fileResult)
    %checkHref Check for no hardcoded links in help text

    %   Copyright 2021-2024 The MathWorks, Inc.

    if fileResult.HelpText == ""
        return;
    end
    status = "Clean";
    h = fileResult.HelpText;
    h = convertCharsToStrings(h);
    hrefPattern = '<a' + whitespacePattern + 'href';
    if contains(h, hrefPattern)
        status = "HREF";
        breakPattern = whitespacePattern(0,inf);
        evalPattern = hrefPattern + breakPattern + "=" + breakPattern + '"matlab:';
        if contains(h, evalPattern)
            status = "Eval";
        end
    end
    switch status
    case "Clean"
        fileResult.Results.NoHardcodedLinks = true;
        fileResult.Results.NoEvalLinks = true;
    case "Eval"
        fileResult.Results.NoHardcodedLinks = false;
        fileResult.Results.NoEvalLinks = false;
    case"HREF"
        fileResult.Results.NoHardcodedLinks = false;
        fileResult.Results.NoEvalLinks = true;
    end
end
