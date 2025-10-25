function fileResult = checkH1(fileResult)
    %checkH1 Checks the H1 line of the help text
    %   A = checkH1(A) will take in a FileInformation object and, if the H1
    %   line is present, set the following properties:
    %   - H1NoLeadingWhitespace
    %   - H1StartsWithFunction
    %   - H1NoEndingPeriod

    %   Copyright 2021-2024 The MathWorks, Inc.

    if fileResult.HelpText == ""
        return;
    end
    H1 = extractBefore(fileResult.HelpText, newline);
    if H1 == ""
        return;
    end
    fileResult.Results.H1NoLeadingWhitespace = ~startsWith(H1, whitespacePattern(2, inf));
    fcnName = fileResult.FunctionName;
    if all(isstrprop(fcnName, 'lower'))
        fcnName = upper(fcnName);
    end
    fileResult.Results.H1StartsWithFunction = startsWith(H1, optionalPattern(whitespacePattern) + fcnName);
    fileResult.Results.H1NoEndingPeriod = ~ endsWith(H1, "." + optionalPattern(whitespacePattern));
end
