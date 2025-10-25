function b = transpose(a) %#codegen
%TRANSPOSE Transpose a categorical matrix.
%   B = TRANSPOSE(A) returns the transpose of the 2-dimensional categorical
%   matrix A.  Note that CTRANSPOSE is identical to TRANSPOSE for categorical
%   arrays.
%
%   TRANSPOSE is called for the syntax A.'.
%
%   See also CTRANSPOSE, PERMUTE.

%   Copyright 2018-2019 The MathWorks, Inc. 

b = categorical(matlab.internal.coder.datatypes.uninitialized());
b.codes = a.codes.';
b.categoryNames = a.categoryNames;
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
b.numCategoriesUpperBound = a.numCategoriesUpperBound;
