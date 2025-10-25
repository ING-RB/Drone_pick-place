function str = createWebWindowHyperlink(windowText,windowTitle,linkLabel)
% This function is undocumented and may change in a future release.

% Copyright 2018-2024 The MathWorks, Inc.

import matlab.automation.internal.diagnostics.CommandHyperlinkableString;

commandTxt = sprintf("%s('%s','%s')", ...
    "matlab.automation.internal.displayToWebWindowAsText", ...
    encode(windowText), encode(windowTitle));

str = CommandHyperlinkableString(linkLabel,commandTxt);
end

function encoded = encode(str)
import matlab.internal.crypto.base64Encode;
encoded = base64Encode(unicode2native(str, "UTF-8"));
end

% LocalWords:  unittest Hyperlinkable unicode
