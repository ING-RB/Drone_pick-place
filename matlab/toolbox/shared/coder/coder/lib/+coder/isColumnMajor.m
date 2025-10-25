function answer = isColumnMajor(varargin)
%CODER.ISCOLUMNMAJOR determines if a function or variable is column-major
%
%   coder.isColumnMajor returns true if the current function uses
%   column-major array layout. coder.isColumnMajor(argument) returns true
%   if the the argument variable uses column-major array layout.
%
%   This function only has an effect for code generation. In MATLAB
%   simulation this function returns true since MATLAB simulation always
%   uses column-major array layout.
%
%   CODER.ISCOLUMNMAJOR()     determines if the array layout for the current
%   function is column-major
%
%   CODER.ISCOLUMNMAJOR(X)    determines if the array layout for the current
%   variable is column-major
%  
%   Example:
%     coder.columnMajor; 
%     x = magic(3); 
%     if coder.isColumnMajor(x)
%         fprintf('This will always be displayed in generated code');
%     else
%         fprintf('This will never be displayed in generated code');
%     end
%

%   Copyright 2017-2019 The MathWorks, Inc.
narginchk(0,1);
answer = true;   % MATLAB simulation is always column-major
