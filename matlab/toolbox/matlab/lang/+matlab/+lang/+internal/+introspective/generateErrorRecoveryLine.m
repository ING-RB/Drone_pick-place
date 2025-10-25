function productLink = generateErrorRecoveryLine(callBack, displayName, varargin)
    if matlab.internal.display.isHot
        if isempty(varargin)
            args = "";
        else
            args = append("'", join(varargin, "', '"), "'");
        end
        productUrl = "matlab:" + callBack + "(" + args + ");";
        productLink = '<a href="' + productUrl + '">' + displayName + '</a>';
    else
        productLink = string(displayName);
    end
end

% Copyright 2020 The MathWorks, Inc.
