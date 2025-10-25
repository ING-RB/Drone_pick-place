function [c,ia,ib] = intersect(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[rows,sorted] = setMembershipFlags(varargin{:});

[aData,bData,c] = datetime.compareUtil(a,b);

if nargout < 2
    cData = intersect(aData,bData,varargin{:});
    if sorted
        cData = setMembershipSort(cData,rows);
    end
else
    [cData,ia,ib] = intersect(aData,bData,varargin{:});
    if sorted
        [cData,ia,ib] = setMembershipSort(cData,ia,ib,rows);
    end
end
c.data = cData;
