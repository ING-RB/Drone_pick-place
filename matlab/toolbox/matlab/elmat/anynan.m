function tf = anynan(X)
%ANYNAN True if at least one element of an array is Not-a-Number.
%   ANYNAN(X) returns true if at least one of the elements of X is NaN and
%   false otherwise.
%   For example, ANYNAN([pi NaN Inf -Inf]) is true.
%
%   See also ISNAN, ISMISSING, ANY, ANYMISSING.

%   Copyright 2021 The MathWorks, Inc.

tf = any(isnan(X), "all");

