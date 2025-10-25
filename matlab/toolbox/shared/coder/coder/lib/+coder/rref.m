function ref = rref(varargin) %#ok<STOUT>
%CODER.RREF Pass data as a read-only reference to a C/C++ function
%
%   CODER.CEVAL('FCN', CODER.RREF(U)...) passes U as a read-only
%   reference to the function FCN.
%   Use CODER.REF only within a call to CODER.CEVAL.
%
%   To pass a read/write parameter to a C function, use CODER.REF;
%   to pass a write-only parameter, use CODER.WREF.
%
%   Example:
%     Consider the following C function foo:
%
%       double foo(const double* p) {
%         return *p + 1;
%       }
%
%     To invoke foo with a read-only input from the generated code, use the
%     following source code:
%
%       u = 42.0;
%       y = 0.0; % Constrain return type to double
%       y = coder.ceval('foo', coder.rref(u));
%       % Now y equals 43
%
%   See also coder.ceval, coder.ref, coder.wref.
%
%   This is a code generation function. In MATLAB, it generates an error.

%   Copyright 2006-2019 The MathWorks, Inc.
error(message('Coder:builtins:NotSupportedInMATLAB','coder.rref'));

