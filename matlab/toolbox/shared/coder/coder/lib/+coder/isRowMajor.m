function answer = isRowMajor(varargin)
%CODER.ISROWMAJOR determines if a function or variable is row-major
%
%   coder.isRowMajor returns true if the current function uses
%   row-major array layout. coder.isRowMajor(argument) returns true
%   if the the argument variable uses row-major array layout.
%
%   This function only has an effect for code generation. In MATLAB
%   this function returns false since MATLAB simulation always
%   uses column-major array layout.
%
%   CODER.ISROWMAJOR()     determines if the array layout for the current
%   function is row-major
%
%   CODER.ISROWMAJOR(X)    determines if the array layout for the current
%   variable is row-major
%
%   Example:
%     coder.rowMajor; 
%     x = magic(3); 
%     if coder.isRowMajor(x)
%         fprintf('This will always be displayed in generated code');
%     else
%         fprintf('This will never be displayed in generated code');
%     end
%

%   Copyright 2017-2019 The MathWorks, Inc.
narginchk(0,1);
answer = false;  % MATLAB simulation is always column-major
