function B = trimdata(A,M,varargin)
%TRIMDATA   Trim data
%   B = TRIMDATA(A,M) trims A, using M to define the size of B. If A is a
%   vector, the trailing elements of A are trimmed. If the length of A is
%   less than M, then the entire vector is returned. If A is a matrix,
%   table, or timetable, it is trimmed to M rows. If A is a
%   multidimensional array, TRIMDATA operates along the first dimension
%   whose size does not equal 1.
%
%   B = TRIMDATA(A,[M1,...,MN]) trims the first N dimensions of A.
%
%   B = TRIMDATA(___,Dimension=DIM) operates along dimension DIM of A. DIM
%   may be a vector of dimensions.
%
%   B = TRIMDATA(___,Side=S) specifies where A is trimmed. S must be:
%       "trailing" - (default) The trailing elements of A are trimmed.
%       "leading"  - The leading elements of A are trimmed.
%       "both"     - A is trimmed on both sides. Half of the elements
%                    trimmed are trailing elements, and half are leading
%                    elements. If there is an odd number of elements to be
%                    trimmed, the extra element is a trailing element.
%
%   Example: Trim a vector
%       A = [1 2 3 4 5];
%       B1 = trimdata(A,2)
%       B2 = trimdata(A,2,Side="leading")
%
%   Example: Remove columns from a matrix
%       A = categorical(diag(1:5));
%       B = trimdata(A,2,Dimension=2)
%
%   Example: Remove rows from a timetable
%       X = [1; 2; 3; 4; 5];
%       TT = timetable(X,Timestep=seconds(0.5));
%       B = trimdata(TT,2)
%
%   Example: Trim the rows and columns of a matrix
%       A = [1 2 3; 4 5 6; 7 8 9];
%       B = trimdata(A,[2 1],Side="both")
%
%   See also PADDATA, RESIZE, HEAD, TAIL.

%   Copyright 2023-2024 The MathWorks, Inc.

B = matlab.internal.math.padortrim(false,true,A,M,varargin{:});
