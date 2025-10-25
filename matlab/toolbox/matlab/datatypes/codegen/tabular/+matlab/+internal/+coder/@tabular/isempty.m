function tf = isempty(t)   %#codegen
%ISEMPTY True for empty table.
%   TF = ISEMPTY(T) returns logical 1 (true) if T is an empty table and logical 0
%   (false) otherwise.  An empty array has no elements, that is PROD(SIZE(T))==0.
%  
%   See also SIZE.

%   Copyright 2019 The MathWorks, Inc. 

tf = (t.rowDimLength() == 0) || (t.varDim.length == 0);
