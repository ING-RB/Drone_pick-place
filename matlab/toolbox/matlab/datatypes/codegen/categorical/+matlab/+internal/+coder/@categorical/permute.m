function b = permute(a,order)  %#codegen
%PERMUTE Permute dimensions of a categorical array.
%   B = PERMUTE(A,ORDER) rearranges the dimensions of the categorical array A
%   so that they are in the order specified by the vector ORDER.  The array
%   produced has the same values as A but the order of the subscripts needed
%   to access any particular element are rearranged as specified by ORDER. The
%   elements of ORDER must be a rearrangement of the numbers from 1 to N.
%
%   See also IPERMUTE, CIRCSHIFT.

%   Copyright 2018-2019 The MathWorks, Inc. 

b = categorical(matlab.internal.coder.datatypes.uninitialized());
% Call the built-in to ensure correct dispatching regardless of what's in order
b.codes = builtin('permute',a.codes,order);
b.categoryNames = a.categoryNames;
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
b.numCategoriesUpperBound = a.numCategoriesUpperBound;

