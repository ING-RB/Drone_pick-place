function [isInputNormalBroadcast, isInputGroupedBroadcast] = isBroadcast(varargin)
%isBroadcast Check if an input argument is has been explicitly broadcasted.
%
% Syntax:
%  [isInputNormalBroadcast, isInputGroupedBroadcast] = isBroadcast(in1,in2,..)
%
% Where:
%  - Each of in1,in2,.. is the input to check if is a broadcast.
%  - isInputNormalBroadcast is a row vector of logicals, each logical is
%    true if and only if the corresponding input is a normal broadcast.
%  - isInputGroupedBroadcast is a row vector of logicals, each logical is
%    true if and only if the corresponding input is a grouped broadcast.
%
% There are two ways an input argument can be broadcasted:
%
%  - Normal broadcast, an array that is to be passed to all invocations of
%    a grouped function across all groups and chunks. For example, the value
%    42 in splitapply(@(x) {x + 42},tX,tG) will be a normal broadcast.
%
%  - Grouped broadcast, a set of arrays with one array per group. Each
%    invocation of a grouped function will receive the array that
%    corresponds to the same group, across all chunks. For example, the
%    output of mean in splitapply(@(x) {x - mean(x)},tX,tG) will be a
%    grouped broadcast.

% Copyright 2017 The MathWorks, Inc.

isInputNormalBroadcast = false(size(varargin));
isInputGroupedBroadcast = false(size(varargin));
for ii = 1 : numel(varargin)
    isInputNormalBroadcast(ii) = isa(varargin{ii}, 'matlab.bigdata.internal.BroadcastArray');
    isInputGroupedBroadcast(ii) = isa(varargin{ii}, 'matlab.bigdata.internal.splitapply.GroupedBroadcast');
end
end
