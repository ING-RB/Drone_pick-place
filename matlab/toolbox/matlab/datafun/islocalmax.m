function [tf, P] = islocalmax(A, varargin)
%ISLOCALMAX   Detect local maxima in data.
%   TF = ISLOCALMAX(A) returns a logical array whose elements are true when
%   a local maximum is detected in the corresponding element of A. If A is
%   a matrix or a table, ISLOCALMAX operates on each column separately. If
%   A is an N-D array, ISLOCALMAX operates along the first array dimension
%   whose size does not equal 1.
%
%   TF = ISLOCALMAX(A,DIM) specifies the dimension to operate along.
%
%   TF = ISLOCALMAX(...,'MinProminence',P) returns only those local maxima
%   whose prominence is at least P. The prominence of a local maximum is
%   the smaller of the largest decrease in value on the left side and on
%   the right side of the local maximum before encountering a larger local
%   maximum. For a vector X, the largest prominence is at most
%   MAX(X)-MIN(X).
%
%   TF = ISLOCALMAX(...,'FlatSelection',F) specifies how local maxima are
%   indicated for flat regions containing repeated local maxima values.
%   F must be:
%       'center'  - (default) middle index of a flat region marked as true.
%       'first'   - first index of a flat region marked as true.
%       'last'    - last index of a flat region marked as true.
%       'all'     - all flat region indices marked as true.
%
%   TF = ISLOCALMAX(...,'MinSeparation',S) specifies S as the minimum
%   separation between local maxima. S is defined in units of the sample
%   points. When S > 0, ISLOCALMAX selects the largest local maximum and
%   ignores all other local maximum within S units of it. The process is
%   repeated until there are no more local maxima detected. By default, S =
%   0.
%
%   TF = ISLOCALMAX(...,'MaxNumExtrema',N) detects no more than the N most
%   prominent local maxima. By default, N is equal to SIZE(A,DIM).
%
%   TF = ISLOCALMAX(...,'SamplePoints',X) specifies the sample points X
%   representing the location of the data in A. X must be a numeric or
%   datetime vector, and must be sorted with unique elements. If the first
%   input is a table, X can also specify a table variable. For example, X
%   can specify time stamps for the data in A. By default, ISLOCALMAX uses
%   data sampled uniformly at points X = [1 2 3 ... ].
%
%   TF = ISLOCALMAX(...,'ProminenceWindow',K) for a positive scalar K
%   computes the prominence of each local maxima only within a window of
%   width K centered around the maxima.  For flat regions, the window
%   extends K/2 units before the first point in the region and K/2 units
%   after the last point in the region.
%
%   TF = ISLOCALMAX(...,'ProminenceWindow',[NB NF]) for non-negative
%   scalars NB and NF computes the prominence of each local maxima only
%   within a window from NB units before the local maxima to NF units after
%   it.  For flat regions, the window extends NB units before the first
%   point in the region and NF units after the last point in the region.
%
%   If 'SamplePoints' are specified, the units of the prominence window are
%   relative to the sample points.
%
%   [TF,P] = ISLOCALMAX(A,...) also returns the prominence for each value
%   of A.  Points that are not local maxima have a prominence of 0.
%
%   Arguments supported only when first input is table or timetable:
%
%   TF = ISLOCALMAX(...,'DataVariables',DV) finds local maxima only in the
%   table variables specified by DV. The default is all table variables in
%   A. DV must be a table variable name, a cell array of table variable
%   names, a vector of table variable indices, a logical vector, a function
%   handle that returns a logical scalar (such as @isnumeric), or a table 
%   vartype subscript. TF has the same size as A. DV cannot be specified if
%   A is not a table or a timetable. Only numeric or logical data variables
%   should be specified.
%
%   TF = ISLOCALMAX(...,'OutputFormat',FORMAT) specifies the format for the  
%   output TF with respect to the table variables. FORMAT must be: 
%   'logical'- (default) TF is a logical array matching the size of A. 
%   'tabular'  - TF is a table or timetable that is the same height as A with
%              logical variables corresponding to specified table variables 
%
%   EXAMPLE: Find local maxima in a vector of data.
%       x = 1:100;
%       A = (1-cos(2*pi*0.01*x)).*sin(2*pi*0.15*x);
%       tf = islocalmax(A);
%
%   EXAMPLE: Filter out less prominent local maxima.
%       A = peaks(256);
%       A = A(:, 150);
%       tf = islocalmax(A, 'MinProminence', 1);
%
%   EXAMPLE: Filter out local maxima too close to each other in time.
%       t = hours(linspace(0, 3, 15));
%       A = [2 4 6 4 3 7 5 6 5 10 4 -1 -3 -2 0];
%       S = minutes(45);
%       tf = islocalmax(A, 'MinSeparation', S, 'SamplePoints', t);
%
%   EXAMPLE: Detect center points of flat maxima regions.
%       x = 0:0.1:10;
%       A = min(0.75, sin(pi*x));
%       tf = islocalmax(A, 'FlatSelection', 'center');
%
%   See also islocalmin, ischange, isoutlier, max, maxk

% Copyright 2017-2022 The MathWorks, Inc.

if nargout > 1
    [tf, P] = matlab.internal.math.isLocalExtrema(A, true, varargin{:});
else
    tf = matlab.internal.math.isLocalExtrema(A, true, varargin{:});
end