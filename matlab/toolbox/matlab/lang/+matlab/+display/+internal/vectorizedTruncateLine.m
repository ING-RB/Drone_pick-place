function truncatedStringArr = vectorizedTruncateLine(stringArr, availableWidth, doesMATLABUseDesktop)
    % This function is unsupported and might change or be removed
    % without notice in a future version.
    % vectorizedTruncateLine Truncates each text element in the input array
    % to fit in the specified width.

    %   Copyright 2023 The MathWorks, Inc.
    arguments
        stringArr
        availableWidth (1,1) double = -1
        doesMATLABUseDesktop (1,1) logical = matlab.internal.display.isDesktopInUse
    end

    truncatedStringArr = strings(size(stringArr));

    isCell = isa(stringArr, "cell");

    for i=1:numel(stringArr)
        if isCell
            truncatedStringArr(i) = matlab.internal.display.truncateLine(stringArr{i}, availableWidth, doesMATLABUseDesktop);
        else
            truncatedStringArr(i) = matlab.internal.display.truncateLine(stringArr(i), availableWidth, doesMATLABUseDesktop);
        end
    end
end
