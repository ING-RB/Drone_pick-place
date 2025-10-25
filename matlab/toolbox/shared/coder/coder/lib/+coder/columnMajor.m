function columnMajor
%CODER.COLUMNMAJOR sets current function and its called functions to use
%column-major array layout
%
%   coder.columnMajor called within a function specifies that the function
%   be generated with column-major array layout. All functions called
%   within the function inherit the column-major specification, unless they
%   specify their own distinct array layout.
%
%   This function only has an effect for code generation. In MATLAB
%   simulation this function is ignored since MATLAB simulation always uses
%   column-major array layout.
%
%   CODER.COLUMNMAJOR()    sets current function as column-major
%
%   Example:
%     coder.columnMajor;
%     if coder.isColumnMajor
%         fprintf('This will always be displayed in generated code');
%     else
%         fprintf('This will never be displayed in generated code');
%     end
%

%   Copyright 2017-2019 The MathWorks, Inc.
