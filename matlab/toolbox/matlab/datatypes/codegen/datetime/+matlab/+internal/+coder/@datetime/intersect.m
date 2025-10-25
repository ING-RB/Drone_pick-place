function [c,iaout,ibout] = intersect(a,b,varargin) %#codegen
%INTERSECT Find datetimes common to two arrays.
%   C = INTERSECT(A,B) for datetime arrays A and B, returns the values common to
%   the two arrays with no repetitions.  C is vector sorted in ascending order.
%
%   A or B can also be a datetime string or a cell array of datetime strings.
%
%   C = INTERSECT(A,B,'rows') for datetime matrices A and B with the same number
%   of columns, returns the rows common to the two matrices. The rows of the
%   matrix C are sorted in ascending order.
%
%   [C,IA,IB] = INTERSECT(A,B) also returns index vectors IA and IB such that C
%   = A(IA) and C = B(IB). If A and B are row vectors, then C will be a row
%   vector as well, otherwise C will be a column vector. IA and IB are column
%   vectors. If there are repeated common values in A or B then the index of the
%   first occurrence of each repeated value is returned.
%
%   [C,IA,IB] = INTERSECT(A,B,'rows') also returns index vectors IA and IB such
%   that C = A(IA,:) and C = B(IB,:).
%
%   [C,IA,IB] = INTERSECT(A,B,'stable') for datetime arrays A and B, returns the
%   values of C in the same order that they appear in A, while INTERSECT(A,B,'sorted')
%   returns the values of C in sorted order.
%
%   [C,IA,IB] = INTERSECT(A,B,'rows','stable') returns the rows of C in the same
%   order that they appear in A, while INTERSECT(A,B,'rows','sorted') returns
%   the rows of C in sorted order.
%
%   Example:
%
%      % Find the intersection between two arrays of datetimes.
%      % Create two arrays of datetimes.
%      dt1 = datetime(2015,10,1,0:4,0,0)
%      dt2 = datetime(2015,10,1,2:2:6,0,0)
%
%      intersect(dt1,dt2)
%
%   See also UNIQUE, UNION, SETDIFF, SETXOR, ISMEMBER.

%   Copyright 2019 The MathWorks, Inc.

[rows,sorted] = setMembershipFlags(varargin{:});

[aData,bData,c] = datetime.compareUtil(a,b);

if sorted
    if rows
        [aData,ia] = sortrows(aData);
        [bData,ib] = sortrows(bData);
    else
        [aData,ia] = sort(aData);
        [bData,ib] = sort(bData);
    end
end

if nargout < 2
    cData = intersect(aData,bData,varargin{:});
    if sorted
        cData = setMembershipSort(cData,rows);
    end
else
    [cData,ia2,ib2] = intersect(aData,bData,varargin{:});
    if sorted
        [cData,iaout,ibout] = setMembershipSort(cData,ia(ia2),ib(ib2),rows);
    else
        iaout = ia2;
        ibout = ib2;
    end
end
c.data = cData;
