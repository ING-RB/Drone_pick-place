function [ellipsisChar, ellipsisWidth] = getEllipsisCharacter()
% Returns the ellipsis character based on what mode MATLAB is operating
% (i.e. desktop vs nodesktop)
% If MATLAB is in desktop mode, it returns the unicode ellipsis character
% (i.e. char(8230) or '\x2026').
% If MATLAB is operating in no desktop it returns 3 dots
% (i.e. "...")

% Copyright 2021-2024 The MathWorks, Inc
if matlab.internal.display.isDesktopInUse
    ellipsisChar = string(char(8230));
else
    ellipsisChar = "...";
end
ellipsisWidth = matlab.internal.display.wrappedLength(ellipsisChar);
end