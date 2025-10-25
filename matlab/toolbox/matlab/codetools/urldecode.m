function urlOut = urldecode(urlIn)
%URLDECODE Replace URL-escaped strings with their original characters
%   This function is unsupported and might change or be removed without
%   notice in a future version.

% Copyright 1984-2021 The MathWorks, Inc.

arguments
    urlIn {mustBeText}
end

urlOut = "";

i = 1;
urlIn = char(urlIn);
while i <= length(urlIn)
    if strcmp(urlIn(i), '+')
        urlOut = urlOut.append(' ');
        i = i + 1;
    elseif strcmp(urlIn(i), '%')
        % Iterate over each hex pair of characters to potentially combine
        % into a single unicode character
        j = 1;
        decChars = [];
        while (i < length(urlIn) && strcmp(urlIn(i), '%'))
            hexStr = urlIn(i+1:i+2);
            decChars(j) = hex2dec(hexStr); %#ok<AGROW> 
            j = j + 1;
            i = i + 3;
        end
        urlOut = urlOut.append(native2unicode(decChars, 'UTF-8'));
    else
        urlOut = urlOut.append(urlIn(i));
        i = i + 1;
    end
end

urlOut = char(urlOut);