function r = ref(varargin) %#ok<STOUT>
%CODER.REF pass data by reference to a C/C++ function in generated code.
%
%   CODER.CEVAL('FCN', CODER.REF(U)...)  passes U by reference to the C
%   function FCN.  Use CODER.REF only within a call to
%   CODER.CEVAL.
%
%   To pass a read-only reference to a C function, use CODER.RREF.  To
%   pass a write-only parameter, use CODER.WREF.
%
%   Example:
%     Consider the following C function foo:
%
%     void foo(double* p) {
%       *p = *p + 1;
%     }
%
%     Pass u by reference to foo, use the following source code:
%
%     u = 42.0;
%     coder.ceval('foo', coder.ref(u));
%     % Now u equals 43
%
%   See also coder.ceval, coder.wref, coder.rref.
%
%   This is a code generation function. In MATLAB, it generates an error.

%   Copyright 2006-2019 The MathWorks, Inc.
error(message('Coder:builtins:NotSupportedInMATLAB','coder.ref'));
