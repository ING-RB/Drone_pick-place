function fh = getCheckedFunctionHandle(obj)
% Generate a wrapped function handle that represents this
% ElementwiseOperation.
% Method overriden from SlicewiseFusableOperation.

%   Copyright 2022 The MathWorks, Inc.

import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;

fh = TaggedArrayFunction.wrap(obj.FunctionHandle, obj.Options);
fh = iWrapFunctionHandle(fh);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function wrappedFcn = iWrapFunctionHandle(originalFcn)
% Wrap the given FunctionHandle object in a function handle that will
% verify the elementwise size constraints.
underlyingFcn = originalFcn.Handle;
wrappedFcn = originalFcn.copyWithNewHandle(@(varargin) iApplyFcn(underlyingFcn, varargin{:}));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = iApplyFcn(fcn, varargin)
% Apply the elementwise function to one chunk of input and assert the
% elementwise size invariant.
expectedSize = iGetExpectedSize(varargin);
varargout = cell(1, nargout);
[varargout{:}] = feval(fcn, varargin{:});
iVerifyExpectedSize(expectedSize, varargout);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function expectedSize = iGetExpectedSize(inputs)
% Get the expected size of the outputs based on the inputs.
expectedSize = size(inputs{1});
for ii = 2:numel(inputs)
    sz = size(inputs{ii});
    expectedSize(end + 1 : numel(sz)) = 1;
    expectedSize(sz ~= 1) = sz(sz ~= 1);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function iVerifyExpectedSize(expectedSize, outputs)
% Verify the outputs match the expected size.
isOutputUnknown = any(cellfun(@matlab.bigdata.internal.UnknownEmptyArray.isUnknown, outputs));
for ii = 1:numel(outputs)
    actualSize = size(outputs{ii});
    if ~isequal(actualSize, expectedSize) && ~isOutputUnknown
        % Allow UnknownEmptyArray to propagate forward
        error(message('MATLAB:bigdata:array:InvalidOutputSize', ...
            ii, mat2str(actualSize), mat2str(expectedSize)));
    end
end
end
