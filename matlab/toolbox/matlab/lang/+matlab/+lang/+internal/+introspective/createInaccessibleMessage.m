function inaccessibleMessage = createInaccessibleMessage(messageID, funcName, lines)
    if numel(lines) > 1
        delimiter = newline + "  ";
        productLinks = char(delimiter + join(lines, delimiter));
    else
        productLinks = lines{1};
    end
    inaccessibleMessage = message(messageID, funcName, productLinks);
end

% Copyright 2020 The MathWorks, Inc.
