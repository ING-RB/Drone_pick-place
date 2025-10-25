function replace(~)
% CODER.REPLACE Replace the current function with a code replacement
% library (CRL) function in the generated code.
%
%   This is a code generation function.  It has no effect in MATLAB 
%   code and MEX building. It generates an error if used within conditional 
%   expressions and loops. This function performs a CRL lookup during 
%   code generation for the following function signature:
%   
%   [Y1_TYPE, Y2_TYPE, ...YN_TYPE] = FCN(X1_TYPE, X2_TYPE, ...XN_TYPE)
% 
%       Y1_TYPE...YN_TYPE     Data types of the outputs of MATLAB function FCN
%       X1_TYPE...XN_TYPE     Data types of the inputs to MATLAB function FCN
%
%   At code generation, the contents of MATLAB function, FCN, are discarded 
%   and replaced with a function call that is registered in CRL as a 
%   replacement for FCN.
%   
%   CODER.REPLACE( ) replaces the current function implementation with a
%   CRL replacement function. If no match is found in the CRL, code is 
%   generated with no replacement for the current function.
%
%   CODER.REPLACE('-errorifnoreplacement') replaces the current function 
%   implementation with a CRL replacement function. If no match is found in
%   the CRL, code generation is halted and an error message describing the 
%   CRL lookup failure is generated.
%
%   CODER.REPLACE('-warnifnoreplacement') replaces the current function 
%   implementation with a CRL replacement function. If no match is found in 
%   CRL, code is generated for the current function and a warning describing
%   the CRL lookup failure is generated during code generation. 
%
%   Example:
%     function out = top_function(in)
%       p = calculate(in);
%       out = exp(p);
%     end
%     
%     function y = calculate(x)
%       % Search in the CRL for replacement and use replacement function
%       % if available
%       coder.replace('-errorifnoreplacement');
%       y = sqrt(x);
%     end
%
%   Assuming the data type of 'x' and 'y' is double, the following conceptual function
%   is searched for in the CRL:
%     double = calculate( double )
%
%   A successful match in the CRL generates the following code:
%   
%     real_T top_function(real_T in)
%     {
%          real_T p;
%          p = replacement_calculate_impl(in);
%          return exp(p);
%     }
%   
%   The contents of function 'calculate' are discarded and replaced with the CRL 
%   replacement function 'replacement_calculate_impl'.

%  Copyright 2012-2019 The MathWorks, Inc.
