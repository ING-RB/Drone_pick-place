function B = resize(A,M,varargin)
%RESIZE   Resize data by adding or removing elements
%   B = RESIZE(A,M) resizes A, using M to define the size of B. If A is a
%   vector and the length of A is less than M, RESIZE pads A with trailing
%   elements. If A is a vector and the length of A is greater than M, then
%   trailing elements are trimmed. If A is a matrix, table, or timetable, A
%   is resized to M rows. If A is a multidimensional array, RESIZE operates
%   along the first dimension whose size does not equal 1.
%
%   B = RESIZE(A,[M1,...,MN]) resizes the first N dimensions of A.
%
%   B = RESIZE(___,Dimension=DIM) operates along dimension DIM of A. DIM
%   may be a vector of dimensions.
%
%   B = RESIZE(___,FillValue=V) pads A with the constant scalar value V. If
%   A is tabular, V can also be a cell array whose elements contain fill
%   values for each table variable.
%
%   B = RESIZE(___,Pattern=PAT) pads according to PAT. PAT must be:
%       "constant" - (default) Data is padded with the default value
%                    determined by the class of A.
%       "edge"     - Endpoints are used as constant fill values.
%       "circular" - Data is repeated circularly.
%       "flip"     - Data is reflected, and endpoints are duplicated.
%       "reflect"  - Data is reflected without duplicating endpoints.
%
%   B = RESIZE(___,Side=S) specifies where A is resized. S must be:
%       "trailing" - (default) A is padded with trailing elements, or the
%                    trailing elements of A are trimmed.
%       "leading"  - A is padded with leading elements, or the leading
%                    elements of A are trimmed.
%       "both"     - A is resized on both sides. Half of the elements
%                    padded/trimmed are trailing elements, and half are
%                    leading elements. If there is an odd number of
%                    elements to be padded/trimmed, the extra element is a
%                    trailing element.
%
%   Example: Pad a vector
%       A = [1 2 3];
%       B1 = resize(A,5)
%       B2 = resize(A,5,Pattern="circular")
%
%   Example: Add columns to a matrix
%       A = categorical(diag(1:3));
%       B = resize(A,5,Dimension=2,FillValue='0')
%
%   Example: Add rows to a timetable
%       TT = timetable([1; 2; 3],Timestep=seconds(0.5));
%       B = resize(TT,5,Pattern="circular")
%
%   Example: Resize the rows and columns of a matrix
%       A = [1 2 3; 4 5 6; 7 8 9];
%       B = resize(A,[1 6],Side="both")
%
%   See also TRIMDATA, PADDATA, RESHAPE, SIZE, REPMAT.

%   Copyright 2023 The MathWorks, Inc.

B = matlab.internal.math.padortrim(true,true,A,M,varargin{:});
end