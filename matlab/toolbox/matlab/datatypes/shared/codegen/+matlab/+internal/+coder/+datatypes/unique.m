function [y, ix, iy] = unique(varargin) %#codegen
%UNIQUE Set unique.
%   MATLAB.INTERNAL.CODER.DATATYPES.UNIQUE is a wrapper around the core unique. If
%   the inputs are compile time constants, then it will use feval to generate a
%   compile time constant output.

%   Copyright 2020 The MathWorks, Inc.

if coder.internal.isConst(varargin)
    % If the inputs are constant use feval to get the unique values at compile time
    [y, ix, iy] = coder.const(@feval,'unique',varargin{:});
else
    % Otherwise simply call codegen unique
    [y, ix, iy] = unique(varargin{:});
end