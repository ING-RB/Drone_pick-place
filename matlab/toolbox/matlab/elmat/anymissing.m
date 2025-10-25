function tf = anymissing(X)
%ANYMISSING True if at least one element of an array is missing.
%   ANYMISSING(X) returns true if at least one of the elements of X is
%   missing and false otherwise.
%   For example, ANYMISSING(["a" "b" missing "d"]) is true.
%
%   See also ISMISSING, ISNAN, ANY, ANYNAN.

%   Copyright 2021 The MathWorks, Inc.

tf = any(ismissing(X), "all");

