function b = ctranspose(a)  %#codegen
%CTRANSPOSE Transpose a categorical matrix.
%   B = CTRANSPOSE(A) returns the transpose of the 2-dimensional categorical
%   matrix A.  Note that CTRANSPOSE is identical to TRANSPOSE for categorical
%   arrays.
%
%   CTRANSPOSE is called for the syntax A'.
%
%   See also TRANSPOSE, PERMUTE.

%   Copyright 2018-2019 The MathWorks, Inc. 

b = categorical(matlab.internal.coder.datatypes.uninitialized());
b.codes = a.codes';
b.categoryNames = a.categoryNames;
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
b.numCategoriesUpperBound = a.numCategoriesUpperBound;
