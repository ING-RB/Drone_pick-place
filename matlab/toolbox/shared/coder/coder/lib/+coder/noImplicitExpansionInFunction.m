function noImplicitExpansionInFunction
%CODER.NOIMPLICITEXPANSIONINFUNCTION suppresses implicit expansion
% of matrix operations in the current function
%
%   coder.noImplicitExpansion called within a function specifies that
%   the function does not support implicit expansion of scalar dimensions,
%   for example, a + mean(a). Functions called by this function do not
%   inherit this suppression.
%
%   This function only has an effect for code generation. In MATLAB simulation 
%   this function is ignored, since MATLAB simulation always supports
%   implicit expansion.
%
%   CODER.NOIMPLICITEXPANSIONINFUNCTION()    sets current function as not
%   supporting implicit expansion
%
%   Example:
%     coder.noImplicitExpansionInFunction;

%   Copyright 2020 The MathWorks, Inc.

