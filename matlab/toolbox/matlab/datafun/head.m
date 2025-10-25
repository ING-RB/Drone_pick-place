function out = head(A, k)
%HEAD Get first rows of array, table, or timetable
%   HEAD(A) displays the first eight rows of the array or table A in the
%   command window without storing a value.
%
%   HEAD(A,K) displays up to K rows from the beginning of A. If A contains
%   fewer than K rows, then the entire array or table is displayed.
%
%   B = HEAD(A) or B = HEAD(A,K) returns the first eight rows, or up to K
%   rows, of the array or table A.
%
%   See also TAIL, TOPKROWS, SIZE

%   Copyright 2016-2022 The MathWorks, Inc.

if nargin<2
    B = matlab.internal.math.headtail(true, A);
else
    B = matlab.internal.math.headtail(true, A, k);
end

if nargout > 0
    out = B;
else
    disp(B);
end