function varargout = validateSameSmallSizes(varargin)
%VALIDATESAMESMALLSIZES Possibly deffered small size validation
%   [TX1,TX2,...] = validateSameSmallSizes(TX1,TX2,...,ERR)
%   validates that each of TX1, TX2, ... all have the same size in all
%   dimensions excluding the first one. If they do not have the same small
%   sizes, the specified error will be thrown. ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%   Inputs TX1, TX2, ... are expected to be strict tall compatible.
%   Otherwise, incompatible tall size error is thrown.

% Copyright 2019 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(3, Inf);
dataArgs = varargin(1:end-1);
err = varargin{end};

% Capture all the outputs since they might be modified.
nData = numel(dataArgs);
assert(nargout == nData, 'Assertion failed: validateSameSmallSizes expects output to be captured.');

assert(~istall(err), 'Assertion failed: validateSameSmallSizes expects ERR not to be tall.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    [varargout{1:nargout}] = iValidateSameSmallSizes(errFcn, dataArgs{:});
catch err
    throwAsCaller(err);
end
end

function varargout = iValidateSameSmallSizes(errFcn, varargin)
% Validate same small sizes with the available information in the adaptors.
% If not, validate lazily.

smallSizes = [];
for ii = 1:numel(varargin)
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(varargin{ii});
    if isempty(adaptor.SmallSizes) || any(isnan(adaptor.SmallSizes))
        % No available information from one of the inputs, validate lazily.
        smallSizes = [];
        break;
    elseif isempty(smallSizes)
        % New size is known, update smallSizes.
        smallSizes = adaptor.SmallSizes;
    else
        % Small sizes are known for the previous and the current argument.
        if numel(adaptor.SmallSizes) ~= numel(smallSizes) ...
                || any(adaptor.SmallSizes ~= smallSizes)
            errFcn();
        end
    end
end

if isempty(smallSizes)
    [varargout{1:nargout}] = slicefun(@(varargin) iCheckSmallSizes(errFcn, varargin{:}), varargin{:});
    for ii = 1:numel(varargout)
        varargout{ii}.Adaptor = matlab.bigdata.internal.adaptors.getAdaptor(varargin{ii});
    end
else
    varargout = varargin;
end
end

function varargout = iCheckSmallSizes(errFcn, varargin)
% Check for equality in small sizes.

initialSize = size(varargin{1});
for ii = 2:numel(varargin)
    sz = size(varargin{ii});
    if numel(initialSize) ~= numel(sz) || any(initialSize(2:end) ~= sz(2:end))
        errFcn();
    end
end
varargout = varargin;
end