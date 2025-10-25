function B = paddata(A,M,varargin)
%PADDATA   Pad data
%   B = PADDATA(A,M) pads A, using M to define the size of B. If A is a
%   vector, PADDATA pads A with trailing elements. If the length of A is
%   greater than M, then A is returned. If A is a matrix, table, or
%   timetable, it is padded to M rows. If A is a multidimensional array,
%   PADDATA operates along the first dimension whose size does not equal 1.
%
%   B = PADDATA(A,[M1,...,MN]) pads the first N dimensions of A.
%
%   B = PADDATA(___,Dimension=DIM) operates along dimension DIM of A. DIM
%   may be a vector of dimensions.
%
%   B = PADDATA(___,FillValue=V) pads A with the constant scalar value V.
%   If A is tabular, V can also be a cell array whose elements contain fill
%   values for each table variable.
%
%   B = PADDATA(___,Pattern=PAT) pads according to PAT. PAT must be:
%       "constant" - (default) Data is padded with the default value
%                    determined by the class of A.
%       "edge"     - Endpoints are used as constant fill values.
%       "circular" - Data is repeated circularly.
%       "flip"     - Data is reflected, and endpoints are duplicated.
%       "reflect"  - Data is reflected without duplicating endpoints.
%
%   B = PADDATA(___,Side=S) specifies where A is padded. S must be:
%       "trailing" - (default) A is padded with trailing elements.
%       "leading"  - A is padded with leading elements.
%       "both"     - A is padded on both sides. Half of the padding
%                    elements are trailing elements, and half are leading
%                    elements. If there is an odd number of elements to be
%                    padded, the extra element is a trailing element.
%
%   Example: Pad a vector
%       A = [1 2 3];
%       B1 = paddata(A,5)
%       B2 = paddata(A,5,Pattern="circular")
%
%   Example: Add rows or columns to a matrix
%       A = categorical(diag(1:3));
%       B1 = paddata(A,5,FillValue='0') % Add rows
%       B2 = paddata(A,5,Dimension=2,FillValue='0') % Add columns
%
%   Example: Add rows to a timetable
%       TT = timetable([1; 2; 3],Timestep=seconds(0.5));
%       B = paddata(TT,5,Pattern="circular")
%
%   Example: Pad the rows and columns of a matrix
%       A = [1 2; 3 4; 5 6];
%       B = paddata(A,[8 6],Side="both")
%
%   See also TRIMDATA, RESIZE, REPMAT.

%   Copyright 2023 The MathWorks, Inc.

B = matlab.internal.math.padortrim(true,false,A,M,varargin{:});
end