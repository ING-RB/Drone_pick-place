%coder package - Functions that control code generation
%
%   Most of these functions have no effect in MATLAB.
%
%   Functions in the coder package:
%     allowpcode      - Control code generation from P-files.
%     ceval           - Call external C functions from generated code.
%     cinclude        - Include a specified header file in generated code.
%     cstructname     - Assign a C type name to a structure in the 
%                       generated code.
%     extrinsic       - Indicate that codegen should not generate code for
%                       a function. Instead call the function in MATLAB.
%     inline          - Control inlining of the current function in the
%                       generated code.
%     inlineCall      - Inline call the provided callee function in the
%                       the generated code.
%     notInlineCall   - Call but do not inline the provided callee function
%                       in the generated code.
%     opaque          - Declare a variable in the generated C code.
%     ref             - Pass data by reference to a C function.
%     rref            - Pass data as a read-only reference to a C function.
%     target          - Determine the current code-generation target.
%     unroll          - Force a FOR loop to be unrolled in the generated 
%                       code.
%     updateBuildInfo - Update the RTW.BuildInfo object.
%     wref            - Pass data as a write-only reference to a C function.
%

% Copyright 1994-2023 The MathWorks, Inc.
