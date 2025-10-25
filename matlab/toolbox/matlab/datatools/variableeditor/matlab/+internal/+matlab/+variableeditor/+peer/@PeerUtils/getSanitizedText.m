% Returns sanitized text that can be passed back to the client for display (in
% error messages, for example)

% Copyright 2014-2023 The MathWorks, Inc.

function s = getSanitizedText(text)
    arguments
        text string
    end
    s = replace(text, ["<", ">", "&"], ["&lt;", "&gt;", "&amp;"]);
end
