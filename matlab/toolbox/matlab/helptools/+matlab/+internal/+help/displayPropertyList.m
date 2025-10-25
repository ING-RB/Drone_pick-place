function displayPropertyList(className, productName)
    classRefItem = getClassRefItem(className, productName);
    shortName = matlab.internal.help.makeStrong(shortenName(className), true, true);
    header = indent(0.5) + getString(message("MATLAB:introspective:helpParts:ClassDetails", shortName));
    helpStr = matlab.internal.help.getClassPropertyGroupHelp(classRefItem, true, indent);
    disp(header + helpStr);
end

%   Copyright 2022 The MathWorks, Inc.
