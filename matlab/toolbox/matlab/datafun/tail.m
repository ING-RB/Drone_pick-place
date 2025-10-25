function out = tail(A, k)
%TAIL Get last rows of array, table, or timetable
%   TAIL(A) displays the last eight rows of the array or table A in the
%   command window without storing a value.
%
%   TAIL(A,K) displays up to K rows from the end of the A. If A contains
%   fewer than K rows, then the entire array or table is displayed.
%
%   B = TAIL(A) or B = TAIL(A,K) returns the last eight rows, or up to K
%   rows, of the array or table A.
%
%   See also HEAD, TOPKROWS, SIZE

%   Copyright 2016-2022 The MathWorks, Inc.

if nargin<2
    B = matlab.internal.math.headtail(false, A);
else
    B = matlab.internal.math.headtail(false, A, k);
end

if nargout > 0
    out = B;
else
    disp(B);
end