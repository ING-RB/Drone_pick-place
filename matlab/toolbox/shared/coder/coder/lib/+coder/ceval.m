function Y = ceval(varargin) %#ok<STOUT>
%CODER.CEVAL Call a C/C++ function from generated code.
%
%  This functions works for code generation only.  In MATLAB, it generates
%  an error.  Use coder.target to write code using coder.ceval that will
%  also run in MATLAB.
%
%  CODER.CEVAL('FCN') calls the C function FCN.
%
%  CODER.CEVAL('FCN',X1,...XN) calls the C function FCN, passing
%  inputs X1 through XN.
%
%  Y = CODER.CEVAL('FCN') calls the C function FCN and assigns the
%  return value to the variable Y.
%
%  Y = CODER.CEVAL('FCN',X1,..XN) calls the C function FCN, passing
%  input parameters X1,..XN, and assigning the return value to the
%  variable Y.
%
%  By default, CODER.CEVAL passes input parameters and return values
%  by value.  To pass data by reference, use:
%
%    coder.ref(X) to pass X as a reference
%    coder.rref(X) to pass X as a read-only reference
%    coder.wref(X) to pass X as a write-only reference
%
%  For example, to call a C function fcn that returns array A, use the
%  following code:
%
%    coder.ceval('fcn',coder.wref(A));
%
%  To call a C function fcn that returns two outputs, A and B
%  (even if they are not arrays), use the following code:
%
%    coder.ceval('fcn',coder.wref(A),coder.wref(B));
%
%  When the address of a global variable is passed via coder.ref,
%  coder.rref or coder.wref and its address is retained by the C code,
%  use the '-global' flag to specify that the address has
%  escaped. This enables synchronization for globals accessed
%  indirectly inside the custom code.
%
%    coder.ceval('-global','fcn',coder.ref(globalVar));
%
%  To specify the array layout used by the invoked C function, use the
%  '-layout' option:
%
%    '-layout:columnMajor' or '-col' to provide data in column-major array layout
%    '-layout:rowMajor' or '-row'    to provide data in row-major array layout
%    '-layout:any'                   to provide data in any array layout
%
%  If the data layout passed between the caller function and the called C
%  function do not match, the data is automatically converted (transposed)
%  at the C function call site. The only exception occurs when the C
%  function uses the '-layout:any' option. In this case, the data is passed
%  to the C function as is, without changing its array layout.
%
%     coder.ceval('-layout:rowMajor','fcn',coder.ref(A));
%
%  See also coder.ref, coder.rref, coder.wref, coder.target, coder.opaque.

%   Copyright 2006-2019 The MathWorks, Inc.
error(message('Coder:builtins:NotSupportedInMATLAB','coder.ceval'));
