function inline(~)
% CODER.INLINE control inlining of the current function in the
% generated code.
%
%   CODER.INLINE('always') forces inlining of the current function in the
%   generated code.
%
%   CODER.INLINE('never') prevents inlining of the current function in the
%   generated code.
%
%   CODER.INLINE('default') uses internal heuristics to determine whether
%   or not to inline the function.
%
%   Example:
%     function y = foo(x)
%       coder.inline('never');
%       y = x;
%     end
%
%   This is a code generation function.  It has no effect in MATLAB.
%   In MATLAB Coder, it has no effect on functions called from inside 
%   PARFOR loops.

%  Copyright 2007-2019 The MathWorks, Inc.

