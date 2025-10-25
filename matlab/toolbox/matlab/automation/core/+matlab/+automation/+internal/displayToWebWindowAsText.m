function displayToWebWindowAsText(encodedWindowText, encodedWindowTitle)
% This function is undocumented and may change in a future release.

% Copyright 2018-2024 The MathWorks, Inc.

import matlab.automation.internal.HTMLCharacterAide;

windowTitle = decode(encodedWindowTitle);
windowTitle = HTMLCharacterAide.escape(windowTitle);

windowText = decode(encodedWindowText);
windowText = HTMLCharacterAide.escapeAllButLinkAndStrongTags(windowText);

htmlTxt = ...
    "<html>" + newline + ...
    "<head>" + newline + ...
    "    <title>" + windowTitle + "</title>" + newline + ...
    "</head>" + newline + ...
    "<body>" + newline + ...
    "    <pre>" + windowText + "</pre>" + newline + ...
    "</body>" + newline + ...
    "</html>";
web("text://" + htmlTxt, '-new', '-noaddressbox');
end

function txt = decode(encoded)
import matlab.internal.crypto.base64Decode;
txt = native2unicode(base64Decode(string(encoded)), "UTF-8");
end

% LocalWords:  unittest noaddressbox unicode
