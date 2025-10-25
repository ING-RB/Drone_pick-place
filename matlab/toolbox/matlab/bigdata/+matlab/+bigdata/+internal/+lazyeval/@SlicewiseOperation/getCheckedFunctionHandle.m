function fh = getCheckedFunctionHandle(obj)
% Generate a wrapped function handle that represents this
% SlicewiseOperation.
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

function expectedTallSize = iGetExpectedSize(inputs)
% Get the expected size of the outputs based on the inputs.
for ii = 1:numel(inputs)
    expectedTallSize = size(inputs{ii}, 1);
    if expectedTallSize ~= 1
        break;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function iVerifyExpectedSize(expectedTallSize, outputs)
% Verify the outputs match the expected size.
for ii = 1:numel(outputs)
    actualTallSize = size(outputs{ii}, 1);
    if ~isequal(actualTallSize, expectedTallSize)
        error(message('MATLAB:bigdata:array:InvalidOutputTallSize', ...
            ii, actualTallSize, expectedTallSize));
    end
end
end
