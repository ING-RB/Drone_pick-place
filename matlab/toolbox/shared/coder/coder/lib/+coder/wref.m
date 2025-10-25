function ref = wref(varargin) %#ok<STOUT>
%CODER.WREF Pass data as a write-only reference to a C function
%
%   CODER.CEVAL('FCN', CODER.WREF(U)...) passes U as a write-only
%     reference to the C function FCN.  Use CODER.WREF only within a call
%     to CODER.CEVAL.
%
%   NOTE:
%   - Function FCN should only write to U. It should not read U prior to
%     writing to it because the initial value of U is undefined.
%   - Function FCN must fully initialize U.
%   - If there are prior assignments to U, the compiler might  remove them.
%
%   Example:
%
%   Consider the following C function init:
%
%     void init(double* array, int numel) {
%         for(int i = 0; i < numel; i++) {
%           array[i] = 42;
%         }
%     }
%
%   To invoke init with a write-only input, use the following source code:
%
%     % Constrain output to an int8 matrix.
%     % The following assignment can be removed by the compiler,
%     % because init is expected to fully define y.
%     y = zeros(5, 10, 'double');
%     coder.ceval('init', coder.wref(y), numel(y));
%     % Now all elements of y equal 42
%
%   See also coder.ceval, coder.rref, and coder.ref.
%
%   This is a code generation function.  In MATLAB, it generates an error.

%   Copyright 2006-2019 The MathWorks, Inc.
error(message('Coder:builtins:NotSupportedInMATLAB','coder.wref'));

