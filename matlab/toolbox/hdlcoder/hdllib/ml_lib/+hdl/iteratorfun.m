function out = iteratorfun(iterFun, I, outputData, varargin)
%HDL.ITERATORFUN Loop over input I to compute output data. The following
% syntax:
%
% out = hdl.iteratorfun(@iterFun, I, outputInitData)
%
% computes output by calling iterFun for each element of I with the syntax:
%
% out_data = iterFun(element, outputInitData, idx).
%
% "outputInitData" should contain initial values for the output. "idx" is
% the iteration number.
%
% The final value of outputInitData is returned as output.
%
% Example: Compute histogram using hdl.iteratorfun
%
%     image = imread('cameraman.tif');
%     hist  = zeros(1, 256, 'uint32');
%     hist  = hdl.iteratorfun(@hist_kernel_fcn, image, hist);
%
%     function count = hist_kernel_fcn(pix, count, idx)
%         count(pix+1) = count(pix+1) + 1;
%     end
%
% Example: Compute the number of elements of an image greater than a
% threshold, using the threshold as an additional kernel argument
%
%     image = imread('cameraman.tif');
%     numElemsAboveThreshold = uint32(0);
%     threshold = cast(100, 'like', image);
%     numElemsAboveThreshold = hdl.iteratorfun(@threshold_kernel_fcn, ...
%         image, numElemsAboveThreshold, threshold);
%
%     function numElemsAboveThreshold = threshold_kernel_fcn( ...
%         pix, numElemsAboveThreshold, idx, threshold)
%
%         if pix > threshold
%             numElemsAboveThreshold = numElemsAboveThreshold + 1;
%         end
%     end
%
% See also hdl.npufun.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

coder.internal.assert(isa(iterFun, 'function_handle'), ...
    'hdlmllib:hdlmllib:KernelMustBeFcnHandle', 'hdl.iteratorfun');
name = func2str(iterFun);
coder.internal.assert(name(1) ~= '@', ...
   'hdlmllib:hdlmllib:KernelMustNotBeAnonymous', 'hdl.iteratorfun');
coder.internal.assert(nargout(iterFun) >= 0, ...
    'hdlmllib:hdlmllib:KernelMustNotUseVarargout', 'hdl.iteratorfun');
coder.internal.assert(nargout(iterFun) == 1, ...
    'hdlmllib:hdlmllib:KernelMustHaveAnOutput', 'hdl.iteratorfun');
coder.internal.assert(nargin(iterFun) >= 0, ...
    'hdlmllib:hdlmllib:KernelMustNotUseVarargin', 'hdl.iteratorfun');

% Get start val for iteration using type based on size of I
N = coder.const(numel(I));
startVal = coder.const(getStartVal(N));
idx = startVal;

% Call the first iteration of iterFun
out = cast(iterFun(I(1, 1, :), outputData, idx, varargin{:}), 'like', outputData);

% output size must be same as outData
coder.internal.assert(isequal(size(out), size(outputData)), ...
    'hdlmllib:hdlmllib:IteratorfunOutputSizeIncorrect');

outputData = out;
firstPass = true;

for ii=startVal:size(I, 1)
    for jj=startVal:size(I, 2)
        if firstPass
            firstPass = false;
        else
            outputData = cast(iterFun(I(ii, jj, :), outputData, idx, varargin{:}), 'like', outputData);
        end

        idx(:) = idx + 1;
    end
end

% It's possible that the output variable's size changed as we iterated
% multiple times. Make sure that the size is *still* consistent
coder.internal.assert(isequal(size(out), size(outputData)), ...
    'hdlmllib:hdlmllib:IteratorfunOutputSizeIncorrect');

out = outputData;
end

function startVal = getStartVal(N)
    if N <= intmax('uint8')
        startVal = uint8(1);
    elseif N <= intmax('uint16')
        startVal = uint16(1);
    elseif N <= intmax('uint32')
        startVal = uint32(1);
    else
        startVal = uint64(1);
    end
end

% LocalWords:  tif Elems npufun
