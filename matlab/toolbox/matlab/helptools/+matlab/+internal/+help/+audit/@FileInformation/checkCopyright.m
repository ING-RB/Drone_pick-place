function fileResult = checkCopyright(fileResult)
    %checkCopyright Check there is no copyright present in help text
    %   A = checkCopyright(A) sets copyright property of fileResult object

    %   Copyright 2021-2024 The MathWorks, Inc.

    if fileResult.HelpText == ""
        return;
    end
    fileResult.Results.NoCopyright = ~contains(fileResult.HelpText, "Copyright " + digitsPattern(4) + wildcardPattern("Except", newline) + "MathWorks");
end
