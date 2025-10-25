function varargout = applyMovingWindow(strideInfo, varargin)
% Common implementation for movingWindow APIs. Apply blockFcn or windowFcn
% depending on the caller function and the selected EndPoints option.

%   Copyright 2018-2023 The MathWorks, Inc.

import matlab.bigdata.internal.util.indexSlices

% The number of outputsLike arguments is equal to the number of requested
% outputs.
numOutputArgs = nargout;
outputsLike = varargin(end - numOutputArgs + 1:end);
varargin(end - numOutputArgs + 1:end) = [];
% Extract input arguments
dataArgs = varargin(1:end);

isBlockProcessing = strideInfo.IsBlockProcessing;
windowFcnNeedsInfo = isBlockProcessing;
assert(xor(isBlockProcessing, isempty(strideInfo.BlockFcn)), 'blockFcn should not be provided by matlab.tall.movingWindow');

% Extract arguments from strideInfo
stride = strideInfo.Stride;
strideIndices = strideInfo.StrideIndices;
window = strideInfo.Window;

% Create info struct for blockFcn and windowFcn in
% matlab.tall.blockMovingWindow
windowSize = sum(window) + 1;
info = struct( ...
    'Stride', stride, ...
    'Window', windowSize);

numSlicesInData = size(dataArgs{1}, 1);

% Create empty output of the same type as the expected result
varargout = cell(1, nargout);
for k = 1:nargout
    varargout{k} = matlab.bigdata.internal.UnknownEmptyArray.build();
end

if isempty(strideIndices)
    % There are no windows that fully overlap with data in this block of X
    return;
end

% Create an empty prototype of each data input for the padding value
startPadding = cellfun(@(x) indexSlices(x, []), dataArgs, 'UniformOutput', false);
endPadding = startPadding;

% Take the first window center in this block and get its initial element.
endPoints = strideInfo.EndPoints;
startIdx = strideIndices(1) - window(1);
if startIdx <= 0
    % The initial element of the first window is out of range in this
    % block.
    if strcmpi(endPoints, 'fill')
        % Compute number of slices to pad at the beginning
        numSlicesToFill = window(1) - strideIndices(1) + 1;
        % Pad with fillValue
        for k = 1:numel(dataArgs)
            startPadding{k} = repmat(strideInfo.FillValue{k}, numSlicesToFill, 1);
        end
    elseif strcmpi(endPoints, 'shrink')
        % This block contains incomplete windows. Use windowFcn.
        isBlockProcessing = false;
    else
        % With 'discard', there are not enough slices in the input to fill
        % a complete window. This happens when there are not enough slices
        % in the last chunk of the current partition and the remaining
        % partitions contain enough data to fill the window. Return empty
        % output for this chunk.
        return;
    end
    % The first element to take from this block of X is its first
    % element.
    startIdx = 1;
end

% Now take the last window center in this block and its ending element
endIdx = strideIndices(end) + window(2);
if endIdx > numSlicesInData
    % The last element of the last window is out of range in this
    % block. At this point, it will only happen when endPoints is
    % 'shrink' or it is a padding sample value (encoded as 'fill')
    assert(~strcmpi(endPoints, 'discard'), ...
        'Assertion failed: block does not contain exact slices for discard.');
    if strcmpi(endPoints, 'fill')
        % Compute number of slices to pad at the end
        numSlicesToFill = endIdx - numSlicesInData;
        % Pad with fillValue
        for k = 1:numel(dataArgs)
            endPadding{k} = repmat(strideInfo.FillValue{k}, numSlicesToFill, 1);
        end
    elseif strcmpi(endPoints, 'shrink')
        % This block contains incomplete windows. Use windowFcn.
        isBlockProcessing = false;
    end
    % The last element to take from this block of X is its last
    % element.
    endIdx = numSlicesInData;
end

try
    % Check that the padding value is of the same type as the input data
    block = cell(1, numel(dataArgs));
    for k = 1:numel(dataArgs)
        data = dataArgs{k};
        if ~isa(startPadding{k}, class(data))
            error(message('MATLAB:bigdata:custom:MismatchPaddingClass', class(startPadding{k}), class(data)));
        elseif ~isa(endPadding{k}, class(data))
            error(message('MATLAB:bigdata:custom:MismatchPaddingClass', class(endPadding{k}), class(data)));
        end
        % Create padded block of data
        smallSubs = repmat({':'}, 1, ndims(data) - 1);
        block{k} = [startPadding{k}; data(startIdx:endIdx, smallSubs{:}); endPadding{k}];
    end
catch err
    % Throw an extra message indicating a problem with the padding sample
    % value.
    err = matlab.bigdata.BigDataException.build(err);
    err = prependToMessage(err, getString(message('MATLAB:bigdata:custom:InconsistentPadding')));
    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
end

if isBlockProcessing
    % Apply processing per block with blockFcn.
    [varargout{1:nargout}] = feval(strideInfo.BlockFcn, info, block{:}, outputsLike{:});
    for k = 1:nargout
        if size(varargout{k}, 1) ~= numel(strideIndices)
            error(message('MATLAB:bigdata:custom:MovingWindowBlockFcnNotAReduction', ...
                size(varargout{k}, 1), numel(strideIndices)));
        end
    end
else
    % Apply processing per window with windowFcn.
    % Loop over the windows centered in strideIndices. Apply offset in this
    % block due to possible padding and the offset given in startIdx to get
    % the first element of the first window within this block.
    strideIndices = strideIndices + size(startPadding{1}, 1) - startIdx + 1;
    for ii = strideIndices
        % Select window in the padded block of data. Take all the available
        % elements even if there are less than window length.
        windowedData = cell(1, numel(block));
        for k = 1:numel(block)
            data = block{k};
            smallSubs = repmat({':'}, 1, ndims(data) - 1);
            windowedData{k} = data(max(1, ii-window(1)):min(size(data, 1), ii+window(2)), smallSubs{:});
        end
        % Call windowFcn for this window
        out = cell(1, nargout);
        if windowFcnNeedsInfo
            [out{1:nargout}] = feval(strideInfo.WindowFcn, info, windowedData{:}, outputsLike{:});
        else
            [out{1:nargout}] = feval(strideInfo.WindowFcn, windowedData{:}, outputsLike{:});
        end
        for k = 1:nargout
            if size(out{k}, 1) ~= 1
                error(message('MATLAB:bigdata:custom:MovingWindowFcnNotAReduction'));
            end
            varargout{k} = [varargout{k}; out{k}];
        end
    end
end
end
