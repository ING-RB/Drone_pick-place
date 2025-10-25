%ClosureFuture
% A class that represents the future to a given output of a closure.
%
% This will automatically update if the underlying closure is replaced by
% the another closure or the output.
%
% Properties:
%    IdStr: Unique ID between closure, promise and future.
%  Promise: A reference to the Promise object corresponding to this future.
%   IsDone: A flag that is true if and only if the value this future
%           represents has been calculated and is available locally.
%    Value: The actual value this has been calculated and is available
%           locally. Otherwise empty.
%

% Copyright 2015-2022 The MathWorks, Inc.
