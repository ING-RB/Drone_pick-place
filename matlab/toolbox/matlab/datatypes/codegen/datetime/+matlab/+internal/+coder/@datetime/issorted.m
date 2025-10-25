function tf = issorted(this,varargin) %#codegen
%ISSORTED   Check if data is sorted.
%   TF = ISSORTED(A) returns TRUE if the elements of A are sorted in
%   ascending order, namely, returns TRUE if A and SORT(A) are identical:
%   - For vectors, ISSORTED(A) returns TRUE if A is a sorted vector.
%   - For matrices, ISSORTED(A) returns TRUE if each column of A is sorted.
%   - For N-D arrays, ISSORTED(A) returns TRUE if A is sorted along its
%     first non-singleton dimension.
%
%   TF = ISSORTED(A,DIM) checks if A is sorted along the dimension DIM.
%
%   TF = ISSORTED(A,DIRECTION) and TF = ISSORTED(A,DIM,DIRECTION) check if
%   A is sorted according to the specified direction. DIRECTION must be:
%       'ascend'          - (default) Checks if data is in ascending order.
%       'descend'         - Checks if data is in descending order.
%       'monotonic'       - Checks if data is in either ascending or
%                           descending order.
%       'strictascend'    - Checks if data is in ascending order and does
%                           not contain duplicates.
%       'strictdescend'   - Checks if data is in descending order and does
%                           not contain duplicates.
%       'strictmonotonic' - Checks if data is either ascending or
%                           descending, and does not contain duplicates.
%
%   TF = ISSORTED(A,...,'MissingPlacement',M) also specifies where missing
%   elements (NaT) should be placed:
%       'auto'  - (default) Missing elements placed last for ascending sort
%                 and first for descending sort.
%       'first' - Missing elements (NaT) placed first.
%       'last'  - Missing elements (NaT) placed last.
%
%   See also SORT, ISSORTEDROWS, SORTROWS, UNIQUE.

%   Copyright 2019-2020 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},'ComparisonMethod'),...
        'MATLAB:sort:InvalidAbsRealType',class(this));
end

if (nargin == 2) && matlab.internal.coder.datatypes.checkInputName(varargin{1},'rows')
    % Use issortedrows because datetime must use 'real' comparison for the
    % complex .data, and issorted(A,'rows') does not support that.
    tf = issortedrows(this.data,'ComparisonMethod','real');
else
    tf = issorted(this.data,varargin{:},'ComparisonMethod','real');
end
