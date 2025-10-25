function out = isCharOrString(arg)
% This undocumented function may be removed in a future release.

%   isCharOrString -  Determines whether an input is a character vector or a MATLAB
%   string scalar.  
%   isCharOrString(s) Returns 1 if S is a character vector or a string.
%                     Returns 1 for empty character vector and empty string.
%                     Returns 0 for ['Hello'; 'JellO'; 'Moose'], as it is a
%                     2-D input. 
%                     Returns 0 for ['A';'B';'C'] as it is a column vector.
%                     Returns 0 for ["Hello", "Hello", "Moose"], as it is a
%                     string vector. 
% 
%   Copyright 2017-2024 MathWorks, Inc.

out = (ischar(arg) && (isrow(arg)|| isempty(arg))) || isStringScalar(arg);
end
