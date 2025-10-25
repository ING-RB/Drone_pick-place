function varargout = movingWindow(fcn, window, varargin)
%MOVINGWINDOW Apply moving window function to blocks of data
% A = MATLAB.TALL.MOVINGWINDOW(FCN,WINDOW,X) applies the function FCN once
% per window as the window moves over the first dimension of X. The output
% A is the vertical concatenation of the results of applying FCN to each
% window.
%
% Applying FCN to each window over the first dimension of X must result in
% a reduction of X. The result of FCN must have size equal to 1 in the
% first dimension.
%
% WINDOW specifies the size of the window to apply. WINDOW can be a
% positive integer scalar that indicates the window length, or a 2-element
% row vector [NB NF] of nonnegative integers. If WINDOW is specified as a
% vector [NB NF], the window includes the previous NB elements, the current
% element, and the next NF elements of the inputs.
%
% MATLAB.TALL.MOVINGWINDOW supports both tall arrays and in-memory arrays.
% If any input argument is tall, then all output arguments are also tall.
% Otherwise, all output arguments are in-memory arrays.
%
% A = MATLAB.TALL.MOVINGWINDOW(...,"Stride",STRIDE) specifies a step size
% between windows. After operating on a window, the calculation advances by
% STRIDE elements before operating on the next window. STRIDE must be a
% positive integer scalar. Its default value is 1.
%
% A = MATLAB.TALL.MOVINGWINDOW(...,"EndPoints",OPTION) controls how FCN
% operates on the endpoints of X, when there are not enough elements to
% complete a window. OPTION can be one of:
%
%   "shrink" (default) - Apply FCN to the available elements of X that are
%                        inside of the window, effectively reducing the
%                        window size to fit X at the endpoints. With this
%                        option, FCN must properly handle both incomplete
%                        and full size windows.
%
%            "discard" - Apply FCN only when the window is filled with
%                        elements of X, discarding incomplete windows at
%                        the end. This truncates the output; for a column
%                        vector X and a window length K, the output has
%                        length FLOOR((LENGTH(X)-K)/STRIDE)+1.
% 
%        Padding value - Apply FCN to full size windows, padding X with the
%                        padding value in OPTION at the endpoints. OPTION
%                        must be of the same type as X. The size of OPTION
%                        in the first dimension must be equal to 1 and the
%                        size in other dimensions must match X.
%
% A = MATLAB.TALL.MOVINGWINDOW(...,"OutputsLike",{PA}) specifies that
% output A has the same type as the prototype array PA. You can use any of
% the input argument combinations in previous syntaxes. Each output of FCN
% must be the same type as PA.
%
% [A,B,...] = MATLAB.TALL.MOVINGWINDOW(FCN,WINDOW,X,Y,...), where FCN is a
% function handle that returns multiple outputs, returns arrays A, B, ...,
% each corresponding to one of the output arguments of FCN. FCN must return
% the same number of output arguments as were requested from MOVINGWINDOW.
% Each output of FCN must be the same type as the first input X. All
% outputs A, B, ..., must have the same height.
%
% [A,B,...] = MATLAB.TALL.MOVINGWINDOW(...,"OutputsLike",{PA,PB,...})
% specifies that outputs A, B, ... have the same types as PA, PB, ...,
% respectively. You can use any of the input argument combinations in
% previous syntaxes. Each output of FCN must be the same type as
% PA, PB, ..., respectively.
%
%
%   See also MATLAB.TALL.BLOCKMOVINGWINDOW, TALL.

%   Copyright 2018-2019 The MathWorks, Inc.

validateattributes(fcn, {'function_handle', 'string', 'char'}, {}, 'matlab.tall.movingWindow', 'FCN');
if ~isa(fcn, 'function_handle')
    fcn = str2func(fcn);
end

tall.checkNotTall(upper(mfilename), 1, window);
validateattributes(window, {'numeric'}, ...
    {'vector', 'nonempty', 'nonsparse', 'finite', 'integer', 'nonnegative'}, 'matlab.tall.movingWindow', 'window'); 
if isscalar(window)
    % Window length cannot be zero
    validateattributes(window, {'numeric'}, {'positive'}, 'matlab.tall.movingWindow', 'window');
    % Convert window length into window vector as [NB NF]
    window = [floor(window/2) ceil(window/2)-1];
else
    validateattributes(window, {'numeric'}, {'numel', 2}, 'matlab.tall.movingWindow', 'window');
end

numOutputs = max(nargout, 1);
[dataArguments, outputsLike, options] ...
    = parseInputs('matlab.tall.movingWindow', numOutputs, varargin{:});

% Padding sample value cannot be tall
if any(cellfun(@istall, options.FillValue))
    error(message('MATLAB:bigdata:custom:PaddingMustNotBeTall'));
end

% If the type of the input arguments is known, check that the padding value
% (if given) is of the same type as the input arguments
if ~options.IsDefaultEndPoints && strcmpi(options.EndPoints, 'fill')
    for k = 1:numel(dataArguments)
        adaptor = matlab.bigdata.internal.adaptors.getAdaptor(dataArguments{k});
        if isTypeKnown(adaptor)
            inputType = adaptor.Class;
            paddingType = class(options.FillValue{k});
            if ~strcmpi(inputType, paddingType)
                % Error if they have different types
                error(message('MATLAB:bigdata:custom:MismatchPaddingClass', paddingType, inputType));
            end
        end
    end
end

% Throw a comprehensive error if outputsLike is tall but data input
% arguments are not.
if any(cellfun(@istall, outputsLike)) && all(cellfun(@(x) ~istall(x), dataArguments))
    error(message('MATLAB:bigdata:custom:NonTallOutputsLikeRequired'));
end

try
    [varargout{1:numOutputs}] = iStencil(fcn, window, dataArguments, outputsLike, options);
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    rethrow(err);
end
end

function varargout = iStencil(fcn, window, dataArguments, outputsLike, options)
% Implementation of matlab.tall.movingWindow

% Ensure any error issued from transform hides this internal frame and
% anything below.
markerFrame = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

useLikeParameters = true;
fcn = wrapUserFunction(fcn, options, useLikeParameters);

inputArguments = [{window}, options, dataArguments, outputsLike];

varargout = cell(1, numel(outputsLike));
hasTallInputs = any(cellfun(@istall, inputArguments));
if hasTallInputs
    % Validate that all data arguments have the same height
    n = numel(dataArguments);
    [dataArguments{1:n}] = validateSameTallSize(dataArguments{:});
    inputArguments = [{window}, options, dataArguments, outputsLike];
    
    opts = matlab.bigdata.internal.PartitionedArrayOptions('RequiresRandState', true);
    [varargout{:}] = stridedstencilfun(opts, fcn, [], inputArguments{:});
    % Check that fcn supports tall like parameters
    varargout = cellfun(@hGetValueImpl, varargout, 'UniformOutput', false);
    varargout = wrapTallLike(varargout, outputsLike);
else
    % Validate that all data arguments have the same height
    checkSameTallSize(dataArguments{:});
    fcn = matlab.bigdata.internal.lazyeval.TaggedArrayFunction.wrap(fcn);
    [varargout{:}] = iFlowthroughStencil(fcn, inputArguments{:});
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = iFlowthroughStencil(stencilFcn, window, options, varargin)

import matlab.bigdata.internal.util.indexSlices

% The number of outputsLike arguments is equal to the number of requested
% outputs.
numOutputArgs = nargout;
outputsLike = varargin(end - numOutputArgs + 1:end);
varargin(end - numOutputArgs + 1:end) = [];
% Extract input arguments
dataArgs = varargin(1:end);

% Extract relative information from info
endPoints = options.EndPoints;

% Get first stride for X
if any(strcmpi(endPoints, {'shrink', 'fill'}))
    % Shrink default behaviour or fill with padding data. Compute
    % the result only with existing elements, even if there are
    % less than the window length. If it is 'fill', fill the
    % remaining elements of the window with padding sample value.
    firstStride = 1;
else
    % 'discard'. Find the first element that contains a full
    % window: NB + 1
    firstStride = window(1) + 1;
end

% Indices in input data
numSlicesInData = size(dataArgs{1}, 1);
strideIndices = firstStride:options.Stride:numSlicesInData;

% Get the last stride according to the 'EndPoints' option.
% For 'shrink' (default) or 'fill', get the lastStride within the size of 
% the input with an incomplete window. This corresponds with
% strideIndices(end). % For 'discard', get the lastStride with full window.
if ~isempty(strideIndices) && strcmpi(endPoints, 'discard')
    while ~isempty(strideIndices) && (numSlicesInData - strideIndices(end) < window(2))
        strideIndices(end) = [];
    end
end

% Early exit for a completely empty array, or when there are not enough
% slices to fill a full-size window with 'discard'. Output will be an empty
% with the same shape as OutputsLike.
if numSlicesInData == 0 ...
        || (strcmpi(endPoints, 'discard') && (numSlicesInData < sum(window) + 1))
    varargout = cellfun(@(x) indexSlices(x, []), outputsLike, 'UniformOutput', false);
    return;
end

strideInfo = struct(...
    'EndPoints', endPoints, ...
    'FillValue', {options.FillValue}, ...
    'Stride', options.Stride, ...
    'StrideIndices', strideIndices, ...
    'IsBlockProcessing', false, ...
    'BlockFcn', [], ...
    'WindowFcn', stencilFcn, ...
    'Window', window);

try
    [varargout{1:nargout}] = matlab.bigdata.internal.lazyeval.applyMovingWindow(...
        strideInfo, dataArgs{:}, outputsLike{:});
catch err
    matlab.bigdata.internal.throw(err);
end
end