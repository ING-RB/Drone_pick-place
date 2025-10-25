function y = unroll(varargin)
%CODER.UNROLL unroll a FOR-loop in generated code
%
%   Loop unrolling is an optimization that clones the body of a loop once
%   for each iteration.  In the generated code, an unrolled loop appears as
%   straight-line code, while preserving the behavior of the original loop.
%
%   This optimization can improve performance for small tight loops.  For
%   large loops, it can lead to long compile times, bloated generated code,
%   and, in some cases, degraded performance.
%
%   for i = CODER.UNROLL(RANGE) fully unrolls the loop.
%
%   CODER.UNROLL()    fully unrolls the loop
%   for i = RANGE 
%
%   for i = CODER.UNROLL(RANGE, FLAG) unrolls the loop if FLAG is true.
%   FLAG is evaluated at code generation time.
%
%   CODER.UNROLL(FLAG)  unrolls the loop if FLAG is true
%   for i = RANGE 
%
%   Example:
%     coder.unroll();
%     for i = 1:nargin
%         sum = sum + varargin{i};
%     end
%
%   This is a code generation function.  It has no effect in MATLAB.

%   Copyright 2007-2019 The MathWorks, Inc.
narginchk(0,2);
if nargout == 0
    return
end
if (nargin == 1) || (nargin==2)
    y = varargin{1};
else
    y = [];
end
