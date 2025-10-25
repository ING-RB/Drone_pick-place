%ISEQUAL True if contexts are the same.
%   IntrospectionContext are equal if they are introspection contexts to the same object.
%
%   ISEQUAL(CONTEXT1, CONTEXT2) performs element-wise comparisons between introspection 
%   context arrays CONTEXT1 and CONTEXT2.  
%   CONTEXT1 and CONTEXT2 must be of the same dimensions unless one is a scalar.
%   The result is a logical array of the same dimensions, where each
%   element is an element-wise equality result.
%
%   If one of CONTEXT1 or CONTEXT2 is scalar, scalar expansion is performed and the 
%   result will match the dimensions of the array that is not scalar.
%
%   TF = ISEQUAL(CONTEXT1, CONTEXT2) stores the result in a logical array of the same 
%   dimensions.
%
%   See also EQ
%
%   Copyright 2024 The MathWorks, Inc.
%   Built-in function.