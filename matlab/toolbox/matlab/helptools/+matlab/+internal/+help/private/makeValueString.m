function argumentString = makeValueString(argument, helpLocation, prefix)
    arguments
        argument     (1,1);
        helpLocation (1,1) string
        prefix       (1,1) string = indent;
    end
    argumentString = argument.Name;
    wantHyperlinks = helpLocation ~= "";
    if wantHyperlinks
        argumentURL = helpLocation + "/" + argument.Href;
        argumentString = matlab.internal.help.createMatlabLink('web', argumentURL, argumentString);
    end
    if argument.Purpose ~= ""
        argumentString = argumentString + " - " + argument.Purpose;
    end
    prefix = indent(0.5) + prefix;
    argumentString = prefix + argumentString + newline;
    if ~isempty(argument.Values)
        argumentString = argumentString + makeValuesList(argument, prefix);
    else
        argumentString = strip(argumentString, 'right');
    end
end

%   Copyright 2021-2024 The MathWorks, Inc.
