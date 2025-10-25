% Different userContexts can register for different row-cut off limits.

% Copyright 2015-2023 The MathWorks, Inc.

function setRowLimitCutoff(this, userContext, limit)
    this.RowLimitForWidthCalc(userContext) = limit;
end
