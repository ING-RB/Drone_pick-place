function [varStr, maxVarLen, lostWidth] = alignTabularVar(varStr, lostWidth, varLength)

    %   Copyright 2023 The MathWorks, Inc.

% Pad the rows of a variable string column with trailing space characters
% to preserve alignment. The cumulative lost padding width for each row
% should always be less than 1. If the cumulative lost padding width for a
% given row plus any new lost padding width (from padding that row in the
% variable string) exceeds 1, then an extra space of padding is added to
% that row and the cumulative lost padding width is decreased by 1. The
% variable length parameter should contain the (potentially fractional)
% length of each row, whereas the maximum variable length is always a
% rounded-up integer.

if isempty(varStr)
    maxVarLen = 0; % always return a scalar
    % leave varStr and lostWidth as is
else
    maxVarLen = max(ceil(varLength));
    postPadLen = maxVarLen - varLength;
    lostWidth = lostWidth + (postPadLen - floor(postPadLen));
    tooLong = lostWidth > 1;
    lostWidth(tooLong) = lostWidth(tooLong) - 1;
    postPadLen(tooLong) = postPadLen(tooLong) + 1;
    ppI = floor(postPadLen);
    for r = 1:max(ppI)
        % add the spaces in place to improve performance
        varStr(ppI >= r,1) = varStr(ppI >= r,1) + " ";
    end
end