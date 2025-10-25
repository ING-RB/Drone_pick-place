function rowMajor
%CODER.ROWMAJOR sets current function and its called functions to use
%row-major array layout
%
%   coder.rowMajor called within a function specifies that the function be
%   generated with row-major array layout. All functions called within the
%   function inherit the row-major specification, unless they specify their
%   own distinct array layout.
%
%   This function only has an effect for code generation. In MATLAB simulation 
%   this function is ignored (with warning) since MATLAB simulation always 
%   uses column-major array layout.
%
%   CODER.ROWMAJOR()    sets current function as row-major
%
%   Example:
%     coder.rowMajor;
%     if coder.isRowMajor
%         fprintf('This will always be displayed in generated code');
%     else
%         fprintf('This will never be displayed in generated code');
%     end
%

%   Copyright 2017-2019 The MathWorks, Inc.

