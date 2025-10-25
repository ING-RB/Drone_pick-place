function varargout = npufun(kernelFun, kernelSize, input_data, options)
%HDL.NPUFUN applies the kernelFun function to each sliding window of
% kernelSize of the input data. The size of the sliding window is
% determined by kernelSize. Function kernelFun is called for each
% kernelSize window of the input and computes an element of the output.
% output_data is same size as input_data.
%
%     output_data = hdl.npufun(kernelFun, kernelSize, input_data);
%
% The size of the output data matches with the size of the input data.
%
% Example: Call npufun to apply image blurring on image input A.
%
%     output_data = hdl.npufun(@blurringKernel, kernelSize, input_data);
%
% Example: Call npufun to blur image with custom boundary constant.
%
%     output_data = hdl.npufun(@blurringKernel, kernelSize, input_data, ...
%         'BoundaryConstant', 5);
%
% Example: Call npufun to blur image with boundary pixels replicated.
%
%     output_data = hdl.npufun(@blurringKernel, kernelSize, input_data, ...
%         'BoundaryMethod', 'replicate');
%
% Example: Call npufun to apply custom coefficient to the input data.
%
%     output_data = hdl.npufun(@blurringKernel, kernelSize, input_data, ...
%         'KernelArg', 3);
%
% Example: Call npufun with kernel returning multiple outputs
%
%     [output_data1, output_data2] = hdl.npufun(@multiOutKernel, ...
%         kernelSize, input_data, 'KernelArg', 3);
%
% See also hdl.iteratorfun.

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

arguments
    kernelFun (1,1) function_handle {mustBeValidKernelFunction}
    kernelSize {mustBeInteger, mustBePositive, mustBeVector, mustBe2D, mustBeConst(kernelSize,'kernelSize')}
end

arguments (Repeating)
    input_data
end

arguments
    options.BoundaryConstant (1,1) ...
        {mustBeNumericOrLogical, mustBeConst(options.BoundaryConstant, 'BoundaryConstant')} = 0
    options.BoundaryMethod (1,:) char ...
        {hdl.internal.mustBeValidBoundaryMethod, mustBeConst(options.BoundaryMethod,'BoundaryMethod')} = 'constant'
end


firstImgIdx = 0;

%% Read in streamed and non-streamed inputs

% All streamed or non-streamed inputs to the kernel will have the
% associated value in this array set to true
isKernelInput = false(1, numel(input_data));

% All streamed inputs to the kernel will have the associated value in this
% array set to true
isStreamedInput = false(1, numel(input_data));

hasNonStreamedInput = false;

for i=coder.unroll(1:numel(input_data))

    if ischar(input_data{i})
        option = lower(input_data{i});

        % Check that this isn't a trailing Name/Value pair with missing
        % Value field
        coder.internal.assert(~strcmpi(option, 'boundaryconstant') && ...
            ~strcmpi(option, 'boundarymethod'), ...
            'hdlmllib:hdlmllib:IncompleteNameValuePair');

        % Check if there are any arguments coming after and
        % that this is a valid option flag
        coder.internal.assert(i+1 <= numel(input_data) && ...
            (strcmpi(option,'kernelarg') || strcmpi(option,'nonsampleinput')), ...
            'hdlmllib:hdlmllib:NpufunInvalidArgument', input_data{i})

        % The next index is a value for the kernel function
        isKernelInput(i+1) = true;
        hasNonStreamedInput = true;

    elseif i==1 || ~ischar(input_data{i-1})
        % If this is the first input or an input not preceeded by a char
        % array option, then it is a streamed input

        % All streamed inputs must come before non-streamed inputs
        coder.internal.assert(~hasNonStreamedInput, ...
            'hdlmllib:hdlmllib:NpufunStreamedInputsMustComeFirst');

        if firstImgIdx == 0
            % This is the first input image we have found. Make sure
            % that it is no more than 2D and that it is non-empty.
            coder.internal.assert(numel(input_data{i}) > 0, ...
                'hdlmllib:hdlmllib:NpufunImageMustNotBeEmpty');
            coder.internal.assert(ndims(input_data{i}) <= 3, ...
                'hdlmllib:hdlmllib:NpufunImageMustBeLtEqTo3D');

            firstImgIdx = i;
        else
            % For later images, make sure that their size matches the
            % first image we found
            firstImg = input_data{firstImgIdx};
            coder.internal.assert(isequal(size(firstImg), size(input_data{i})), ...
                'hdlmllib:hdlmllib:NpufunImagesMustBeSameSize');
        end

        % Mark this index as a streamed kernel input
        isKernelInput(i) = true;
        isStreamedInput(i) = true;
    end
end

inputIdxs = find(isKernelInput);
streamedIdxs = find(isStreamedInput(isKernelInput));

allInputs = cell(1, numel(inputIdxs));

for i=1:numel(inputIdxs)
    allInputs{i} = input_data{inputIdxs(i)};
end

coder.internal.assert(numel(streamedIdxs) > 0, 'hdlmllib:hdlmllib:NpufunNeedsInputImage');

argOptions = options;

% Padding configuration defaults
%   argOptions.CentreBias: [1, 2] bool
%       Is the kernel center biased towards [top, back (left)] Only used
%       with even kernel sizes.
%   argOptions.PadIdx: [1, 4] uint
%       The max num. samples to pad on [back (left), top, front (right),
%       bottom]. Not used for 'Constant' or 'Replicate'
%   argOptions.MirrorOrigin: [1, 4] uint
%       The origin [back (left), top, front (right), bottom] from which
%       samples are mirrored. Not used with 'Constant' or 'Replicate'

% Defaults
argOptions.CentreBias   = true(1, 2); % top-left
argOptions.PadIdx       = zeros(1, 4);
argOptions.MirrorOrigin = zeros(1, 4);

argOptions.BoundaryMethod = lower(argOptions.BoundaryMethod);

%% Apply kernel function
sampleOutput = allInputs{streamedIdxs(1)};
[outSizeX, outSizeY, outSizeZ] = size(sampleOutput);

% Store all config parameters for use in codegen
coder.hdl.internal.npuconfig(outSizeX, outSizeY, outSizeZ, kernelSize(1), ...
    kernelSize(2), argOptions.BoundaryMethod, argOptions.BoundaryConstant, ...
    numel(streamedIdxs));

if strcmpi(argOptions.BoundaryMethod, 'reflection')
    % PadIdx
    argOptions.PadIdx(1:2) = flip( ceil(kernelSize / 2) - 1 + ~argOptions.CentreBias); % Back  (left)  / Top
    argOptions.PadIdx(3:4) = flip(floor(kernelSize / 2)     - ~argOptions.CentreBias); % Front (right) / Bottom
    % Origin
    argOptions.MirrorOrigin(:) = 2;
end

if coder.target('hdl')
    WindowIdxHandle = @getIdxsConstant;
else
    switch argOptions.BoundaryMethod
        case 'constant'
            WindowIdxHandle = @getIdxsConstant;
        case 'replicate'
            WindowIdxHandle = @getIdxsReplicate;
        case 'reflection'
            WindowIdxHandle = @getIdxsMirror;
    end
end

% get idx offsets for x and y
xIdxOffs = getIdxOffsets(kernelSize(1), argOptions.CentreBias(1));
yIdxOffs = getIdxOffsets(kernelSize(2), argOptions.CentreBias(2));

% call the function once to initialize the output(s)
numOut = nargout(kernelFun);
outs = cell(1, numOut);

% Boundary method doesn't matter for initialization
window = WindowIdxHandle(xIdxOffs, yIdxOffs, coder.internal.ignoreRange(1), ...
    coder.internal.ignoreRange(1), outSizeX, outSizeY, argOptions);
[outs{:}] = callKernelFcn(kernelFun, allInputs, streamedIdxs, window, argOptions);

% Initialize the output image(s)
imagesOut = cell(1, numOut);
for i=1:numOut
    if outSizeZ  > 1
        % 3D input scalar output per depth
        coder.internal.assert((length(outs{i}) == outSizeZ), ...
            'hdlmllib:hdlmllib:NpufunKernelMustHaveScalarOutputsPerDepth');
        imagesOut{i} = repmat(outs{i}(1), outSizeX, outSizeY, outSizeZ);
        imagesOut{i}(1,1,:) = outs{i}; % update values for first window across planes.
    else
        % 2D/1D input scalar output
        coder.internal.assert(isscalar(outs{i}), ...
            'hdlmllib:hdlmllib:NpufunKernelMustHaveScalarOutputs');

        imagesOut{i} = repmat(outs{i}, outSizeX, outSizeY);
    end
end

for i=1:outSizeX
    for j=1:outSizeY
        if i == 1 && j == 1
            continue;
        end

        window = WindowIdxHandle(xIdxOffs, yIdxOffs, i, j, outSizeX, outSizeY, argOptions);
        [outs{:}] = callKernelFcn(kernelFun, allInputs, streamedIdxs, window, argOptions);

        for k=1:numOut
            imagesOut{k}(i, j, :) = outs{k};
        end
    end
end

varargout = imagesOut;

end

%% Helper functions

function idxOffs = getIdxOffsets(kernelSize, centreBias)

halfKernelSize = floor(kernelSize / 2);

if mod(double(kernelSize), 2) == 0
    idxOffs = -(halfKernelSize - centreBias) : 1 : (halfKernelSize - ~centreBias);
else
    idxOffs = -halfKernelSize : halfKernelSize;
end

end

function [xIdxRange, yIdxRange, xIsOOB_pre, xIsOOB_post, yIsOOB_pre, yIsOOB_post] = getBaseIdxRange(xIdxOffs, yIdxOffs, xIdx, yIdx, outSizeX, outSizeY)
xIdxRange = xIdx + xIdxOffs;
yIdxRange = yIdx + yIdxOffs;

xIsOOB_pre  = xIdxRange < 1;
xIsOOB_post = xIdxRange > outSizeX;
yIsOOB_pre  = yIdxRange < 1;
yIsOOB_post = yIdxRange > outSizeY;
end

function window = getIdxsConstant(xIdxOffs, yIdxOffs, xIdx, yIdx, outSizeX, outSizeY, ~)
% determine indices for the current window
[xIdxRange, yIdxRange, xIsOOB_pre, xIsOOB_post, yIsOOB_pre, yIsOOB_post] = getBaseIdxRange(xIdxOffs, yIdxOffs, xIdx, yIdx, outSizeX, outSizeY);

xIdxRange(xIsOOB_pre) = 1;
yIdxRange(yIsOOB_pre) = 1;
xIdxRange(xIsOOB_post) = outSizeX;
yIdxRange(yIsOOB_post) = outSizeY;

window.xPadIsOOB = xIsOOB_pre | xIsOOB_post;
window.yPadIsOOB = yIsOOB_pre | yIsOOB_post;

window.xIdxRange = xIdxRange;
window.yIdxRange = yIdxRange;
end

function window = getIdxsReplicate(xIdxOffs, yIdxOffs, xIdx, yIdx, outSizeX, outSizeY, ~)
% determine indices for the current window
[xIdxRange, yIdxRange, xIsOOB_pre, xIsOOB_post, yIsOOB_pre, yIsOOB_post] = getBaseIdxRange(xIdxOffs, yIdxOffs, xIdx, yIdx, outSizeX, outSizeY);

window.xPadIsOOB = xIsOOB_pre | xIsOOB_post;
window.yPadIsOOB = yIsOOB_pre | yIsOOB_post;

xIdxRange(xIsOOB_pre) = 1;
yIdxRange(yIsOOB_pre) = 1;
xIdxRange(xIsOOB_post) = outSizeX;
yIdxRange(yIsOOB_post) = outSizeY;

window.xIdxRange = xIdxRange;
window.yIdxRange = yIdxRange;
end

function window = getIdxsMirror(xIdxOffs, yIdxOffs, xIdx, yIdx, outSizeX, outSizeY, options)
% Determine indices for the current window
[xIdxRange, yIdxRange, xIsOOB_pre, xIsOOB_post, yIsOOB_pre, yIsOOB_post] = getBaseIdxRange(xIdxOffs, yIdxOffs, xIdx, yIdx, outSizeX, outSizeY);

% Mirrored padding pixel indexes
if any(yIsOOB_pre) % Back
    yIdxRange(yIsOOB_pre)  = (options.MirrorOrigin(3) + options.PadIdx(1) - yIdx) : -1 : options.MirrorOrigin(3);
end
if any(xIsOOB_pre) % Top
    xIdxRange(xIsOOB_pre)  = (options.MirrorOrigin(2) + options.PadIdx(2) - xIdx) : -1 : options.MirrorOrigin(2);
end
if any(yIsOOB_post) % Front
    yIdxRange(yIsOOB_post) = (outSizeY - options.MirrorOrigin(1) + 1) : -1 : (2 * outSizeY - options.MirrorOrigin(1) - options.PadIdx(3) - yIdx + 2);
end
if any(xIsOOB_post) % Bottom
    xIdxRange(xIsOOB_post) = (outSizeX - options.MirrorOrigin(4) + 1) : -1 : (2 * outSizeX - options.MirrorOrigin(4) - options.PadIdx(4) - xIdx + 2);
end

% Account for edge cases where padding extends beyond input bounds
xPadIsOOB = xIdxRange < 1 | xIdxRange > outSizeX;
yPadIsOOB = yIdxRange < 1 | yIdxRange > outSizeY;

xIdxRange(xPadIsOOB) = 1;
yIdxRange(yPadIsOOB) = 1;

window.xIdxRange = xIdxRange;
window.yIdxRange = yIdxRange;
window.xPadIsOOB = xPadIsOOB;
window.yPadIsOOB = yPadIsOOB;
end


%% Kernel Function Caller
function varargout = callKernelFcn(kernelFun, allInputs, imagesIdx, window, options)

coder.inline('always');

% If boundary method is 'constant', overwrite the relevant cells in the loop
useReplicate = strcmpi(options.BoundaryMethod, 'replicate');

% Calculate windows
allInputsWithWindows = cell(1, numel(allInputs));
for ii = coder.unroll(1:numel(allInputs))
    if ismember(ii, imagesIdx)
        img = allInputs{ii};
        wdw = img(window.xIdxRange, window.yIdxRange, :);
        if ~useReplicate
            wdw(window.xPadIsOOB, :,                :) = options.BoundaryConstant;
            wdw(:,                window.yPadIsOOB, :) = options.BoundaryConstant;
        end
        allInputsWithWindows{ii} = wdw;
    else
        allInputsWithWindows{ii} = allInputs{ii};
    end
end

% Apply kernel function to window
pixelsOut = cell(1, nargout(kernelFun));
[pixelsOut{:}] = kernelFun(allInputsWithWindows{:});

varargout = pixelsOut;
end

%% Argument Validation Functions

function mustBeValidKernelFunction(kernelFun)
name = func2str(kernelFun);
coder.internal.assert(name(1) ~= '@', ...
    'hdlmllib:hdlmllib:KernelMustNotBeAnonymous', 'hdl.npufun');
coder.internal.assert(nargout(kernelFun) ~= 0, ...
    'hdlmllib:hdlmllib:KernelMustHaveAnOutput', 'hdl.npufun');
coder.internal.assert(nargout(kernelFun) > 0, ...
    'hdlmllib:hdlmllib:KernelMustNotUseVarargout', 'hdl.npufun');
coder.internal.assert(nargin(kernelFun) >= 0, ...
    'hdlmllib:hdlmllib:KernelMustNotUseVarargin', 'hdl.npufun');
end

function mustBe2D(kernelSize)
coder.internal.assert(numel(kernelSize) == 2, ...
    'hdlmllib:hdlmllib:NpufunKernelSizeIncorrect');
end

function mustBeConst(arg, name)
coder.internal.prefer_const(arg);
coder.internal.assert(~coder.target('hdl') || coder.internal.isConst(arg), ...
    'hdlmllib:hdlmllib:ArgumentMustBeConstant', name, 'hdl.npufun');
end

% LocalWords:  iteratorfun boundaryconstant boundarymethod kernelarg nonsampleinput OOB
