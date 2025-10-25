function h = height(t)  %#codegen
%HEIGHT Number of rows in a table.
%   H = HEIGHT(T) returns the number of rows in the table T.  HEIGHT(T) is
%   equivalent to SIZE(T,1).
%  
%   See also WIDTH, SIZE, NUMEL.

%   Copyright 2019 The MathWorks, Inc. 

h = t.rowDimLength();
