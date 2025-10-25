function out = parallelize(varargin)
%
% This is an internal function for code generation.
%
% This is for the one-liners to apply loop transform parallelize such as
% coder.parallelize('i') OR
% coder.parallelize 
% the last one applies to the adjacent loop

%#codegen
%   Copyright 2021 The MathWorks, Inc.
    coder.internal.preserveFormalOutputs;
    out = coder.loop.Control;
    out = out.parallelize(varargin{:});
end