function prev = hEmptyPoolPreviousTicBytesResult(new)
% This function holds the last value of ticBytes when called on an
% empty pool (which is when there is no pool). We need to hold this
% somewhere to indicate that ticBytes has actually been called.

%   Copyright 2019 The MathWorks, Inc.

persistent EMPTY_POOL_PREVIOUS_TIC_BYTES_RESULT
prev = EMPTY_POOL_PREVIOUS_TIC_BYTES_RESULT;
if nargin == 1
    EMPTY_POOL_PREVIOUS_TIC_BYTES_RESULT = new;
end
end
