function [X, varargout] = gather( X, varargin )
%GATHER collect values into current workspace
%    X = GATHER(A), where A is a tall array, returns an array in the local
%    workspace formed from the contents of A.
%
%    X = GATHER(A), where A is a codistributed array, returns a replicated
%    array with all the data of the array on every lab. This would
%    typically be executed inside SPMD statements, or in parallel jobs.
%
%    X = GATHER(A), where A is a distributed array, returns an array in the
%    local workspace with the data transferred from the multiple labs. This
%    would typically be executed outside SPMD statements.
%
%    X = GATHER(A), where A is a gpuArray, returns an array in the local
%    workspace with the data transferred from the GPU device.
%
%    If A is not one of the types mentioned above, then no operation is
%    performed and X is the same as A.
%
%    [X,Y,Z,...] = GATHER(A,B,C,...) gathers multiple arrays.
%
%    See also TALL, DISTRIBUTED, CODISTRIBUTED, GPUARRAY.

% Copyright 2016-2024 The MathWorks, Inc.

%#codegen

% We only get here if the first object input does not have a gather method
% and is not inferior to the other objects. So let's check the rest of the
% inputs and gather accordingly.

if nargout > nargin
    coder.internal.error("MATLAB:bigdata:array:GatherInsufficientInputs");
end

% If we don't have more than one input it is not possible for a later input
% to need gathering. Using a named variable for this case rather than
% varargin/out improves performance for one-input calls.
if nargin <= 1
    return
end

% Operate in-place on varargout. All inputs are gathered to ensure
% side-effects such as those in some tall arrays take place.
varargout = varargin;

% Coder does not support any types that need gathering.
if ~isempty(coder.target)
    return
end

% If no objects (or no objects that can be remote-arrays) are being
% returned then we don't need to check dispatch.
skipGather = matlab.bigdata.internal.canSkipGather(varargout{:});
if all(skipGather)
    return
end

% We have at least something that might need gathering. Go through the
% non-skipped inputs and gather in groups based on class.
argsToGather = varargout(~skipGather);

% We will group together different classes and gather each group
clz = strings(size(argsToGather));
for n = 1:numel(argsToGather)
    clz(n) = class(argsToGather{n});
end
unqClz = unique(clz);

% To avoid infinite recursion, take care to avoid all inputs being the same
% class if that class does not implement gather (since we would just
% re-call this function).
if isscalar(unqClz) && ~any(skipGather)
    return
end

for cc=1:numel(unqClz)
    % Gather all inputs of a given class at once
    idx = (clz == unqClz(cc));
    [argsToGather{idx}] = gather(argsToGather{idx});
end

varargout(~skipGather) = argsToGather;
end
