function emph = emphasizeText(str)
%emphasizeText - wrap text with <strong></strong> if supported

% Copyright 2015-2019 The MathWorks, Inc.

if matlab.internal.display.isHot
    emph = sprintf('<strong>%s</strong>', str);
else
    emph = sprintf('%s', str);
end
end
