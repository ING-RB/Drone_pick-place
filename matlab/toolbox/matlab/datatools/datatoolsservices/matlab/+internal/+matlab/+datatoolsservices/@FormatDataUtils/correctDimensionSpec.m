% All internal datatools functions will return the multiplication symbol in
% dimensions, like "1×1 object".  But sometimes disp will return ascii 'x', and
% this function will be used to replace it with the multiplication symbol.  This
% way the Workspace Browser and Variable Editor functions are all consistent in
% their display.
%
% This is needed because the command line uses isDesktopInUse to determine if it
% should show ascii 'x' or the multiplication symbol.  So if isDesktopInUse
% returns false (which happens in MATLAB Online and Mobile), then we need to
% replace the ascii 'x'.

% Copyright 2015-2023 The MathWorks, Inc.

function d = correctDimensionSpec(dispData)
    if ~internal.matlab.datatoolsservices.FormatDataUtils.getDesktopInUse
        charReturn = false;
        if ischar(dispData)
            dispData = string(dispData);
            charReturn = true;
        end
        s = split(dispData, " ");

        if isscalar(s)
            d = dispData;
            if charReturn
                d = char(d);
            end
        else
            if isscalar(dispData)
                s2 = strrep(s(1), "x", internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL);
                d = s2 + " " + s(2);
            else
                s2 = strrep(s(:,1), "x", internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL);
                d = s2 + " " + s(:,2);
            end

            if charReturn
                d = char(d);
            elseif iscell(dispData)
                d = cellstr(d);
            end
        end
    else
        d = dispData;
    end
end