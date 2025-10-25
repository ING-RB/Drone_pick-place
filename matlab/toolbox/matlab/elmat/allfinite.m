function tf = allfinite(X)
%ALLFINITE True if every element of an array is finite.
%   ALLFINITE(X) returns true if all the elements of X are finite and
%   false otherwise.
%   For example, ALLFINITE([pi NaN Inf -Inf]) is false.
%
%   See also ISNAN, ISINF, ALL.

%   Copyright 2021 The MathWorks, Inc.

tf = all(isfinite(X), "all");

