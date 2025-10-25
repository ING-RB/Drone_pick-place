function [sortedk,ind] = topkrows(this,k,varargin) %#codegen
%TOPKROWS Top K sorted rows of datetime array.
%   B = TOPKROWS(A,K) returns the top K rows of A sorted in 
%   descending order as a group. A must be a 2-D datetime array.
%
%   B = TOPKROWS(A,K,COL) sorts the top K rows according to the columns
%   specified by the vector COL.
%
%   B = TOPKROWS(...,DIRECTION) also specifies the sort direction(s).
%   DIRECTION can be:
%       'descend' - (default) Sorts in descending order.
%        'ascend' - Sorts in ascending order.
%
%   Use a different sorting direction for each column by specifying
%   DIRECTION as a cell array. For example, TOPKROWS(A,2,[2 3],{'ascend'
%   'descend'}) gets the top 2 rows by first sorting rows in ascending
%   order according to column 2; then, rows with equal entries in column 2
%   get sorted in descending order according to column 3.
%
%   [B,I] = TOPKROWS(...) also returns an index vector I that describes
%   the order of the K selected rows such that B = A(I,:).
%
%   See also SORTROWS, MAXK, MINK.

%   Copyright 2019 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
 coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),...
        'MATLAB:topkrows:InvalidAbsRealType',class(this));
end

% Lexicographic sort of complex data
if nargout < 2
    newdata = topkrows(this.data,k,varargin{:},'ComparisonMethod','real');
else
    [newdata,ind] = topkrows(this.data,k,varargin{:},'ComparisonMethod','real');
end

sortedk = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
sortedk.fmt = this.fmt;
sortedk.tz = this.tz;
sortedk.data = newdata;